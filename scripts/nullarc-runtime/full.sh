#!/bin/bash
# 完成 GPU 电源启动、GART/MES 初始化，并执行指定的队列初始化步骤；超时只终止本次初始化进程树。
# 关键：mesboot 某些硬件超时仍会返回进程退出码 0，因此必须检查实际硬件回读文本。
set +e

G=/Users/Shared/gpu
export HOME=/Users/Shared

SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO=sudo

. "$G/watchdog.sh"
trap 'phx_watchdog_cancel' EXIT

run_mesboot() {
    if [ -n "$SUDO" ]; then
        "$SUDO" "$G/phxctl/mesboot" "$@"
    else
        "$G/phxctl/mesboot" "$@"
    fi
}

# 默认执行 GPU 固件和 SMU 初始化；仅在本次会话已独立验证成功时，才允许显式跳过。
if [[ "${PHX_SKIP_BRINGUP:-0}" == "1" ]]; then
    echo "PHX_SKIP_BRINGUP=1：复用当前会话已验证的 PSP/TMR/IMU/RLC/SMU 状态，不重复发送固件或 SMU 命令"
else
    bash "$G/bringup5.sh"
    BRINGUP_RC=$?
    if [ "$BRINGUP_RC" -ne 0 ]; then
        echo "[错误] bringup5 阶段失败（退出码 $BRINGUP_RC），不再继续 GART/MES"
        exit "$BRINGUP_RC"
    fi
fi

# 使用独立可追踪的看门狗进程，成功后按 PID 取消。
phx_watchdog_start 240 || exit 50
echo "== 看门狗：GART/MES 阶段 240 秒超时保护 =="

if [ -n "$SUDO" ]; then
    "$SUDO" "$G/phxctl/phxctl" wreg 0xDE0 1
    "$SUDO" "$G/phxctl/phxctl" wreg 0xA802 0
    "$SUDO" "$G/phxctl/phxctl" wreg 0xA803 0x01000000
else
    "$G/phxctl/phxctl" wreg 0xDE0 1
    "$G/phxctl/phxctl" wreg 0xA802 0
    "$G/phxctl/phxctl" wreg 0xA803 0x01000000
fi

# 修改：mesboot gart 的程序退出码不能代表硬件成功，必须核对 GART invalidation ack 和 context0。
GART_OUT="$(run_mesboot gart 2>&1)"
GART_RC=$?
printf '%s\n' "$GART_OUT"
if [ "$GART_RC" -ne 0 ] || ! printf '%s\n' "$GART_OUT" | grep -Eq '^gart: ack17=0x[1-9a-fA-F][0-9a-fA-F]* ctx0=0x[1-9a-fA-F][0-9a-fA-F]*$'; then
    echo "[错误] GART 硬件回读不通过（ack17 或 ctx0 为 0），停止后续初始化"
    exit 31
fi

# 修改：检查 MES 两条管线的 ACTIVE 位（bit 26/27），不能只检查 mesboot 退出码。
MES_OUT="$(run_mesboot mes 2>&1)"
MES_RC=$?
printf '%s\n' "$MES_OUT"
MES_HEX="$(printf '%s\n' "$MES_OUT" | /usr/bin/sed -nE 's/^mes: CP_MES_CNTL=0x([0-9a-fA-F]+)$/\1/p' | /usr/bin/tail -1)"
if [ "$MES_RC" -ne 0 ] || [ -z "$MES_HEX" ] || ! /usr/bin/python3 -c 'import sys; v=int(sys.argv[1], 16); sys.exit(0 if (v & 0x0c000000) == 0x0c000000 else 1)' "$MES_HEX"; then
    echo "[错误] MES PIPE0/PIPE1 未同时 ACTIVE，停止后续初始化"
    exit 32
fi

# 保持原有环境变量接口；未传入的参数按空值处理。
if [ -n "$SUDO" ]; then
    STEP_OUT="$("$SUDO" env \
        MESBOOT_MC="${MC:-}" MESBOOT_CS="${CS:-}" MESBOOT_VMT="${VMT:-}" \
        PTE_SYS="${PS:-}" PTE_NOFB="${NF:-}" FAULT_DEFAULT="${FD:-}" PT_SYS="${PTS:-}" \
        VARONLY="${VAR:-}" PTE_EXTRA="${PX:-}" ROOT_FL="${RF:-}" AGPTEST="${AG:-}" \
        CTX0_OFF="${C0:-}" VM8="${V8:-}" VM8_MT="${VMT8:-}" IB0="${IB0:-}" \
        VM8_FLAT="${FLAT:-}" VM8_SYS="${VSYS:-}" ADOPT="${ADOPT:-}" \
        MESBOOT_GFX="${GFX:-}" ADOPT_GFX="${AG:-}" VM8_IBSYS="${IBSYS:-}" VM8_HI="${VHI:-}" \
        "$G/phxctl/mesboot" "$1" 2>&1)"
    STEP_RC=$?
else
    STEP_OUT="$(env \
        MESBOOT_MC="${MC:-}" MESBOOT_CS="${CS:-}" MESBOOT_VMT="${VMT:-}" \
        PTE_SYS="${PS:-}" PTE_NOFB="${NF:-}" FAULT_DEFAULT="${FD:-}" PT_SYS="${PTS:-}" \
        VARONLY="${VAR:-}" PTE_EXTRA="${PX:-}" ROOT_FL="${RF:-}" AGPTEST="${AG:-}" \
        CTX0_OFF="${C0:-}" VM8="${V8:-}" VM8_MT="${VMT8:-}" IB0="${IB0:-}" \
        VM8_FLAT="${FLAT:-}" VM8_SYS="${VSYS:-}" ADOPT="${ADOPT:-}" \
        MESBOOT_GFX="${GFX:-}" ADOPT_GFX="${AG:-}" VM8_IBSYS="${IBSYS:-}" VM8_HI="${VHI:-}" \
        "$G/phxctl/mesboot" "$1" 2>&1)"
    STEP_RC=$?
fi
printf '%s\n' "$STEP_OUT"

# 修改：kiqsched 的成功条件按队列 fence、scratch 测试和接管结果核验。
if [ "$1" = "kiqsched" ]; then
    if [ "$STEP_RC" -ne 0 ] \
        || printf '%s\n' "$STEP_OUT" | grep -q -- '-> TIMEOUT' \
        || ! printf '%s\n' "$STEP_OUT" | grep -Eq '^mes SET_HW_RESOURCES: .* -> OK$' \
        || ! printf '%s\n' "$STEP_OUT" | grep -Eq '^mes QUERY_SCHED_STATUS: .* -> OK$' \
        || ! printf '%s\n' "$STEP_OUT" | grep -Eq '^mes ADD_QUEUE\(compute, map_legacy_kq\): .* -> OK$' \
        || ! printf '%s\n' "$STEP_OUT" | grep -Eq '^mes ADD_QUEUE\(gfx, map_legacy_kq\): .* -> OK$' \
        || ! printf '%s\n' "$STEP_OUT" | grep -Eq '^compute: scratch0=0xdeadbeef .*testbuf=0xfeedf00d .*hqd_active=[1-9]' \
        || ! printf '%s\n' "$STEP_OUT" | grep -Eq '^adopt queue -> kr 0x0$' \
        || ! printf '%s\n' "$STEP_OUT" | grep -Eq '^gfx: scratch1=0xdeadbeef .*testbuf=0x6f7a6f7a' \
        || ! printf '%s\n' "$STEP_OUT" | grep -Eq '^adopt gfx queue -> kr 0x0$'; then
        echo "[错误] KIQ/MES/compute/GFX 队列验证失败，详见上方输出"
        phx_watchdog_cancel
        exit 33
    fi
else
    if [ "$STEP_RC" -ne 0 ] || printf '%s\n' "$STEP_OUT" | grep -q -- '-> TIMEOUT'; then
        echo "[错误] MES 步骤 $1 失败"
        phx_watchdog_cancel
        exit 34
    fi
fi

phx_watchdog_cancel
echo "MES 步骤 $1 完成，硬件回读检查通过"
exit 0
