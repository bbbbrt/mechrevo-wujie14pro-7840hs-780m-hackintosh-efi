#!/bin/bash
# Radeon 780M（GC 11.0.1）启动：PSP 固件准备、RLC 自加载以及 SMU GFX IMU 启用；超时只终止本次初始化进程树。
set -u

G=/Users/Shared/gpu
export HOME=/Users/Shared

P() {
    if [ "$(id -u)" -eq 0 ]; then
        "$G/phxctl/phxctl" "$@"
    else
        sudo "$G/phxctl/phxctl" "$@"
    fi
}

. "$G/watchdog.sh"
phx_watchdog_start 180 || exit 2
RING_CREATED=0
cleanup_bringup() {
    # 诊断模式退出时销毁本次临时 PSP 环；正常启动则保留给后续 GPU 阶段。
    if [[ "${PHX_TMR_DRY_RUN:-0}" == "1" || "${PHX_TMR_SETUP_ONLY:-0}" == "1" || "${PHX_SMU_DIAG_ONLY:-0}" == "1" ]] && [ "$RING_CREATED" = "1" ]; then
        echo "== 诊断模式：销毁临时 PSP 命令环 =="
        P psp destroy || true
    fi
    phx_watchdog_cancel
}
trap cleanup_bringup EXIT

echo "== 看门狗：180 秒内未完成才重启 =="

# 重新建立 PSP 命令环；旧环不存在时 destroy 返回失败属于可忽略情况。
P psp destroy >/dev/null 2>&1 || true
PSP_CREATE="$(P psp create 0x1100000 2>&1)"
echo "$PSP_CREATE"
# 修改：既检查 IOKit 返回值，也要求 PSP 命令环地址确实非零。
if ! printf '%s\n' "$PSP_CREATE" | grep -Eq 'kr 0x00000000 .*ring MC 0x[1-9a-fA-F][0-9a-fA-F]*'; then
    echo "[错误] PSP 命令环未建立，停止后续 GPU 初始化"
    exit 20
fi
RING_CREATED=1

STAGE_OUT="$(P stage "$G/fw/psp_13_0_4_toc.bin" 256 2304 0x0 2>&1)"
echo "$STAGE_OUT"
# 修改：TOC 固件必须完整暂存 2304 字节，避免文件截断被误判为成功。
if ! printf '%s\n' "$STAGE_OUT" | grep -Fq ':+2304]'; then
    echo "[错误] PSP TOC 固件暂存失败"
    exit 21
fi

# 修改：检查 PSP 两条原始初始化命令的内核通信结果，失败时不继续固件加载。
RAW1="$(P raw 0x20 0x0D000000 0x80 0x900 0 0 0 2>&1)"
echo "$RAW1"
# 修改：PSP 的设备执行状态也必须为 0，不能只看 IOKit 传输成功。
if ! printf '%s\n' "$RAW1" | grep -q 'kr 0x00000000  status 0x00000000'; then
    echo "[错误] PSP LOAD_TOC 命令执行失败"
    exit 23
fi

# 修改：LOAD_TOC 响应中的 tmr_size 位于命令缓冲区响应区 +16 字节。
# PSP 环在 0x1100000，命令缓冲区相对偏移 0x4000，响应区偏移 864 字节。
# 通过 BAR0 显存只读接口读取 PSP 实际要求的 TMR 大小，不再猜测大小。
TMR_SIZE_OUT="$(P vram 0x1104370 1 2>&1)"
echo "$TMR_SIZE_OUT"
TMR_SIZE_HEX="$(printf '%s\n' "$TMR_SIZE_OUT" | sed -nE 's/^vram\+0x[0-9a-fA-F]+: ([0-9a-fA-F]{8})$/0x\1/p' | tail -1)"
if ! [[ "$TMR_SIZE_HEX" =~ ^0x[0-9a-fA-F]+$ ]]; then
    echo "[错误] 无法读取 PSP LOAD_TOC 返回的 TMR 大小"
    exit 24
fi

TMR_SIZE=$((TMR_SIZE_HEX))
# 修改：PSP 返回的大小必须不超过驱动预留的 80 MiB，起点与大小按 AMD 驱动的 1 MiB 粒度对齐。
TMR_OFF=$((0x8000000))
TMR_CAP=$((0x5000000))
TMR_ALIGN=$((0x100000))
if (( TMR_SIZE <= 0 || TMR_SIZE > TMR_CAP || TMR_SIZE % TMR_ALIGN != 0 || TMR_OFF % TMR_ALIGN != 0 )); then
    echo "[错误] PSP 返回的 TMR 大小无效/超出 80 MiB 预留区，或未按 1 MiB 对齐：$TMR_SIZE_HEX"
    exit 24
fi

echo "PSP LOAD_TOC 要求 TMR 大小：$TMR_SIZE_HEX"
# 只读诊断模式：读取大小后退出，清理临时 PSP 环，不执行 SETUP_TMR/固件加载/SMU。
if [[ "${PHX_TMR_DRY_RUN:-0}" == "1" ]]; then
    echo "PHX_TMR_DRY_RUN=1：TMR 参数已核验，本轮不提交 SETUP_TMR"
    exit 0
fi

# 通过 PhxBringup 的 pspCtl 路径，按本机 VRAM 基址和系统物理地址计算 TMR 参数。
TMR_OUT="$(P tmr "$TMR_SIZE_HEX" 2>&1)"
echo "$TMR_OUT"
if ! printf '%s\n' "$TMR_OUT" | grep -q 'kr 0x00000000  status 0x00000000'; then
    echo "[错误] PSP SETUP_TMR 失败；停止 GPU 固件加载"
    exit 25
fi

# 修改：TMR 专项测试模式在 SETUP_TMR 成功后立即退出，不加载其他 GPU 固件或启用队列。
if [[ "${PHX_TMR_SETUP_ONLY:-0}" == "1" ]]; then
    echo "PHX_TMR_SETUP_ONLY=1：PSP 已接受 74 MiB TMR；本轮不继续 GPU 初始化"
    exit 0
fi

echo "== 加载 GC 11.0.1 固件 =="
FWLOG="$G/fwaddr.log"
L() {
    local output
    output="$(P loadfw "$@" 2>&1)"
    printf '%s\n' "$output" | grep 'loadfw' >> "$FWLOG" || true
}
: > "$FWLOG"

L "$G/fw/gc_11_0_1_pfp.bin" 256 263168 2 0x000000
L "$G/fw/gc_11_0_1_me.bin" 256 263168 1 0x100000
L "$G/fw/gc_11_0_1_mec.bin" 256 267008 4 0x200000
L "$G/fw/sdma_6_0_1.bin" 256 17408 71 0x380000
L "$G/fw/sdma_6_0_1.bin" 17664 16896 72 0x3C0000
L "$G/fw/gc_11_0_1_mes_2.bin" 256 135648 33 0x400000
L "$G/fw/gc_11_0_1_mes_2.bin" 135904 131072 34 0x440000
L "$G/fw/gc_11_0_1_mes1.bin" 256 104272 81 0x480000
L "$G/fw/gc_11_0_1_mes1.bin" 104528 131072 82 0x4C0000

# 修改：恢复 11 月 17 日 16:47 已验证的原始 IMU 顺序：68 -> 69 -> RLC -> AUTOLOAD_RLC -> SMU。
# 本机 type 68 历史返回 TEE_ERROR_NO_DATA；保留该响应作为日志，继续提交 type 69。
echo "== IMU：按原始顺序提交 type 68、type 69 =="
L "$G/fw/gc_11_0_1_imu.bin" 256 66048 68 0x500000
L "$G/fw/gc_11_0_1_imu.bin" 0x10300 66048 69 0x600000
if ! grep -q 'fwtype 69 .*kr 0x00000000  status 0x00000000' "$FWLOG"; then
    echo "[错误] 本机 IMU 固件类型 69 未被 PSP 接受；停止 SMU 初始化"
    exit 26
fi

L "$G/fw/gc_11_0_1_rlc.bin" 25344 2560 20 0x700000
L "$G/fw/gc_11_0_1_rlc.bin" 27904 21104 21 0x720000
L "$G/fw/gc_11_0_1_rlc.bin" 49008 66048 26 0x800000
L "$G/fw/gc_11_0_1_rlc.bin" 115056 33280 48 0x840000
L "$G/fw/gc_11_0_1_rlc.bin" 148336 8704 25 0x880000
L "$G/fw/gc_11_0_1_rlc.bin" 256 25088 8 0x300000

# 修改：关键固件类型必须由 PSP 成功接受；否则在 GART/MES 写寄存器前提前退出。
for fwtype in 2 1 4 71 72 33 34 81 82 20 21 26 48 25 8; do
    if ! grep -q "fwtype $fwtype .*kr 0x00000000  status 0x00000000" "$FWLOG"; then
        echo "[错误] 固件类型 $fwtype 加载失败，详见 $FWLOG"
        exit 22
    fi
done

echo "== AUTOLOAD_RLC =="
AUTOLOAD_OUT="$(P autoload 2>&1)"
echo "$AUTOLOAD_OUT"
if ! printf '%s\n' "$AUTOLOAD_OUT" | grep -q 'kr 0x00000000  status 0x00000000'; then
    echo "[错误] AUTOLOAD_RLC 失败，停止 GPU 初始化"
    exit 30
fi

# 修改：检查 SMU 的实际响应，不再只看命令行程序是否退出为 0。
require_smu_ok() {
    local message="$1"
    local argument="$2"
    local description="$3"
    local output
    output="$(P smu "$message" "$argument" 2>&1)"
    echo "$output"
    if ! printf '%s\n' "$output" | grep -q 'kr 0x00000000 resp 0x01 (OK)'; then
        echo "[错误] SMU $description 没有返回 OK；中止，不继续写 GART/MES"
        return 1
    fi
}

echo "== SMU 初始化（Linux 驱动顺序） =="
require_smu_ok 0x03 0 "GetDriverIfVersion" || exit 41
require_smu_ok 0x02 0 "GetPmfwVersion" || exit 42
require_smu_ok 0x16 1 "EnableGfxImu" || exit 43

sleep 2
P regs 0xee7e 0x21a0 0x2004 0x263e
echo "GPU 固件与 SMU 阶段完成"

# 修改：SMU 专项诊断模式在固件和 SMU 验证后退出，不执行 GART/MES、队列接管或显示接管。
if [[ "${PHX_SMU_DIAG_ONLY:-0}" == "1" ]]; then
    echo "PHX_SMU_DIAG_ONLY=1：固件和 SMU 阶段通过；本轮不执行 GART/MES/claim"
    exit 0
fi
