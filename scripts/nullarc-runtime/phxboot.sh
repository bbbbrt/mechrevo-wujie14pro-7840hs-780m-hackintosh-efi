#!/bin/bash
# 每次启动：初始化 GPU 内核、先开放应用 Metal，再分阶段接入内屏显示管线。
# PhxAMDFB 启动 hold 最长 120 秒；脚本完成 GPU 队列、应用加速和显示管线核验后才释放。
# 显示异常优先用 nvaccel_iop / phxagdc 运行时降档，等待后再升档重试，不以整机重启作为自动恢复手段。
# phxboot.pending 仅用于识别未完成的启动流程；检测到后原地降档并继续，不主动重启。
# Kill switch: the file $G/phxboot-off.
G=/Users/Shared/gpu; export HOME=/Users/Shared
LOG=/var/log/phxboot.log; MARK=/var/db/phxboot.pending; OFF=$G/phxboot-off
ALLOW=/Library/GPUBundles/nvmtl-allow.txt; DR=/Library/Logs/DiagnosticReports
exec >>"$LOG" 2>&1
echo "== $(date '+%F %T') phxboot"
release() { sysctl -w debug.phxfb_hold=0 >/dev/null 2>&1; }
# NVRAM changes reach flash on a clean shutdown only, unless forced: the arming written after a good boot was lost when
# the battery ran out overnight, and the next boot left WindowServer on the firmware framebuffer (2026-10-22)
nv_commit() { nvram IONVRAM-FORCESYNCNOW-PROPERTY=phxfb >/dev/null 2>&1; }

# 持久启用标记：每次启动完成或失败后，为下一次正常启动重新设置一次性许可。
# 不会主动重启；删除 phxboot-m2.keep 或创建 phxboot-off 即可停止自动接管尝试。
arm_next_boot() {
    [ -e "$OFF" ] && return 0
    [ -e "$G/phxboot-m2.keep" ] || return 0
    if nvram phxfb-boot=1 >/dev/null 2>&1; then
        nv_commit
        echo "PhxAMDFB persistent arm: next boot is armed (phxboot-m2.keep)"
    else
        echo "WARNING: failed to arm phxfb-boot for the next boot"
    fi
}
# 任何正常退出/失败退出都尝试续期；显式 kill switch 优先级最高。
trap 'arm_next_boot' EXIT

# 修改：先尊重停止开关，避免 kill switch 生效时仍写入启动标记。
if [ -e "$OFF" ]; then echo "kill switch present: nothing to do"; release; exit 0; fi

# 修改：先检查 Xcode 许可与首次启动组件；未就绪时不向 GPU 提交固件或寄存器命令。
if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
    echo "Xcode 许可或首次启动组件尚未完成；本轮跳过 GPU 初始化，避免 MES 工具失败后留下半初始化状态"
    release
    exit 0
fi
echo "Xcode 首次启动状态检查通过"

# 修改：每个 macOS 启动周期只允许完整初始化一次，防止同一启动中重复 destroy PSP 环并重刷 SMU。
BOOT_ID="$(sysctl -n kern.boottime 2>/dev/null | sed -nE 's/^[{] sec = ([0-9]+),.*/\1/p')"
BOOT_MARK=/var/db/phxboot.attempted-boot
if [ -z "$BOOT_ID" ]; then
    echo "无法读取 kern.boottime，按安全策略跳过 GPU 初始化"
    release
    exit 0
fi
if [ -r "$BOOT_MARK" ] && [ "$(cat "$BOOT_MARK" 2>/dev/null)" = "$BOOT_ID" ]; then
    echo "本次 macOS 启动周期已经尝试过 GPU 初始化；拒绝重复刷写 PSP/SMU，请在下次干净启动时重试"
    release
    exit 0
fi
printf '%s\n' "$BOOT_ID" > "$BOOT_MARK"
sync

apps_only() { printf '# phxboot: Metal for the built-in test tools only\n' > $ALLOW; }
# every process gets the Metal device; WindowServer too once the accelerator is armed (NullMoth's own default list).
# Denied ("-name", before "*"): the background neural-network users. mediaanalysisd (Photos analysis, which starts by
# itself on an idle Mac on power) ran Espresso convolution kernels and hung the GPU within seconds (2026-10-21), and
# Spotlight and photoanalysisd load the same MPS/Espresso kernels; on the CPU they only take longer.
# iconservicesagent was denied once too, for flat yellow/green icons; that was the plugin's storage-texture aliasing
# (fixed 2026-10-21).
DENY="mediaanalysisd photoanalysisd Spotlight intelligencecontextd intelligentroutingd modelmanagerd biomed biomesyncd corebrightnessd QuickLookUIService"
all_apps() { { printf '# phxboot: Metal for every app%s\n' "$1"; for d in $DENY; do printf -- '-%s\n' "$d"; done
               printf '*\n'; [ -z "$2" ] || printf '%s\n' "$2"; } > $ALLOW; }
# 低档模式：普通应用继续使用 GPU，暂时不让 WindowServer 使用 GPU。
apps_metal_no_ws() {
    { printf '# phxboot: 应用 Metal 保留；WindowServer 暂不接管\n'; for d in $DENY; do printf -- '-%s\n' "$d"; done; printf -- '-WindowServer\n*\n'; } > "$ALLOW"
}

# 运行时降档：只关闭显示事务和 AGDC，不卸载 GPU 内核驱动。
m2_display_down() {
    echo "M2 降档：关闭 AGDC/显示事务，保留 GPU 内核和应用 Metal"
    sysctl -w debug.nvaccel_iop=0 >/dev/null 2>&1 || true
    sysctl -w debug.phxagdc=0 >/dev/null 2>&1 || true
}
# 运行时升档：重新注册扫描输出管线并创建 AGDC。
m2_display_up() {
    echo "M2 升档：重新打开显示事务、扫描输出和 AGDC"
    sysctl -w debug.nvaccel_iop=1 >/dev/null 2>&1 || true
    sysctl -w debug.nvaccelfb=3 >/dev/null 2>&1 || true
    sysctl -w debug.nvaccel_iop_sse=1 >/dev/null 2>&1 || true
    sysctl -w debug.nvaccel_iop_vsync=1 >/dev/null 2>&1 || true
    sysctl -w debug.phxagdc=1 >/dev/null 2>&1 || true
    all_apps "; WindowServer composites on the 780M (runtime re-arm)" '!WindowServer'
}
# 显示异常时先降档 30 秒，再升档并验证；不重启整台电脑。
m2_soft_retry() {
    local reason="$1" iop agdc piped before after
    echo "M2 runtime repair: $reason"
    before=$(ls "$DR" 2>/dev/null | grep -c '^WindowServer[-_]' || true)
    m2_display_down
    sleep 30
    m2_display_up
    sleep 15
    iop=$(sysctl -n debug.nvaccel_iop 2>/dev/null || echo 0)
    agdc=$(sysctl -n debug.phxagdc 2>/dev/null || echo -1)
    piped=$(sysctl -n debug.nvaccel_heads_piped 2>/dev/null || echo 0)
    after=$(ls "$DR" 2>/dev/null | grep -c '^WindowServer[-_]' || true)
    echo "M2 runtime check: iop=$iop agdc=$agdc heads_piped=$piped WindowServer_reports=$before->$after"
    if [ "$iop" = 1 ] && [ "$agdc" = 1 ] && [ $((piped & 1)) -eq 1 ] && pgrep -qx WindowServer && [ "$after" -le "$before" ]; then
        echo "M2 runtime repair passed"
        return 0
    fi
    echo "M2 runtime repair failed; retaining lower display mode without reboot"
    m2_display_down
    apps_metal_no_ws
    return 1
}
# 固件或 GPU 队列初始化失败时保留现场，不再用整机重启恢复。
m2_abort() {
    echo "M2 initialization failed ($1): keep current boot alive; no automatic reboot"
    m2_display_down
    apps_metal_no_ws
    release
    rm -f "$MARK"
    # 若持久标记存在，退出时的 arm_next_boot 会为下一次人工启动续期；phxboot-off 可阻止续期。
    sync
}

# PhxAMDFB comes from the Aux KC, which loads well after PhxBringup: wait for the panel's framebuffer (PhxAMDFB, or
# IONDRV when PhxAMDFB was not armed) before telling which one took it
wait_fb() { for i in $(seq 1 90); do ioreg -rc IOFramebuffer -d0 | grep -q 'class ' && break; sleep 1; done; }
if [ -e "$OFF" ]; then echo "kill switch present: nothing to do"; release; exit 0; fi
if [ -e "$MARK" ]; then
    echo "previous attempt did not finish: in-place display downgrade; continue without reboot"
    rm -f "$MARK"
    m2_display_down
    release
fi
for i in $(seq 1 60); do ioreg -l | grep -q '"phx-build"' && break; sleep 1; done
wait_fb
M2=0; ioreg -rc PhxAMDFB -d0 | grep -q PhxAMDFB && M2=1
if ! ioreg -l | grep -q '"phx-build"'; then
    if [ "$M2" = 1 ]; then m2_abort "PhxBringup not loaded"; else echo "PhxBringup not loaded"; fi
    exit 0
fi
echo "PhxAMDFB on the panel: $M2"
touch "$MARK"; sync
apps_only
# 诊断模式：完整保留固件加载、MES 队列初始化和 GPU claim 的输出，避免 grep 把失败原因过滤掉。
MC=1 CS=1 ADOPT=1 GFX=1 AG=1 bash "$G/full.sh" kiqsched 2>&1 | tee -a "$G/phxboot-detail.log" | grep -E "^compute:|^gfx:|adopt"
FULL_RC=${PIPESTATUS[0]}
echo "full.sh kiqsched exit=$FULL_RC"
# 修改：GPU 固件/SMU/GART/MES 任一阶段失败，禁止继续 claim。
if [ "$FULL_RC" -ne 0 ]; then
    echo "GPU bring-up failed (exit=$FULL_RC)，中止后续队列接管"
    if [ "$M2" = 1 ]; then
        m2_abort "GPU bring-up exit $FULL_RC"
        exit 0
    fi
    apps_only
    release
    rm -f "$MARK"
    sync
    exit 0
fi

echo "[claim] 开始 GPU 队列接管"
CLAIM_OUT="$("$G/phxctl/mesboot" claim 2>&1)"
CLAIM_RC=$?
printf '%s\n' "$CLAIM_OUT" | tee -a "$G/phxboot-detail.log"
# 修改：mesboot claim 的 C 程序即使硬件返回错误也可能退出 0，必须核对实际输出。
if [ "$CLAIM_RC" -ne 0 ] || [ "$CLAIM_OUT" != "claim -> kr 0x0" ]; then
    CLAIM_RC=1
    echo "GPU claim 失败，停止本轮启动"
    if [ "$M2" = 1 ]; then
        m2_abort "GPU claim exit $CLAIM_RC"
        exit 0
    fi
    apps_only
    release
    rm -f "$MARK"
    sync
    exit 0
fi
# no BO cache flushing per submit/wait (the GPU maps system memory snooped): 41 fps window drag instead of 13, and no
# artifacts seen (2026-10-20)
sysctl -w debug.phxbos_flush=0 >/dev/null 2>&1
for i in $(seq 1 20); do ioreg -rc NMXAccel -d0 | grep -q NMXAccel && break; sleep 1; done
if ! ioreg -rc NMXAccel -d0 | grep -q NMXAccel; then
    if [ "$M2" = 1 ]; then m2_abort "NMXAccel did not start"; exit 0; fi
    echo "NMXAccel did not start; no reboot, will retry on a later boot"
    release
    rm -f "$MARK"
    exit 0
fi
if [ "$M2" = 1 ]; then
    # 阶段一：GPU 内核和普通应用 Metal 先工作，WindowServer 暂不接入显示事务。
    sysctl -w debug.nvaccelfb=1 >/dev/null 2>&1
    sysctl -w debug.nvaccel_iop=0 >/dev/null 2>&1
    sysctl -w debug.phxagdc=0 >/dev/null 2>&1
    apps_metal_no_ws
    echo "M2 stage 1: app Metal only; wait 30 s before display-pipe upgrade"
    sleep 30
    MTL_OUT="$($G/phxctl/mtlprobe 2>&1)"
    printf '%s\n' "$MTL_OUT" | tee -a "$G/phxboot-detail.log"
    if ! printf '%s\n' "$MTL_OUT" | grep -q 'results: 4096/4096 correct'; then
        m2_abort "stage 1 Metal compute smoke test failed"
        exit 0
    fi
    # 阶段二：重新开启显示事务、扫描输出管线和 AGDC，启动 hold 仍然保持。
    sysctl -w debug.nvaccel_iop=1 >/dev/null 2>&1
    sysctl -w debug.nvaccelfb=3 >/dev/null 2>&1
    sleep 3
    sysctl -w debug.phxagdc=1 >/dev/null 2>&1
    sleep 15
    IOP_NOW=$(sysctl -n debug.nvaccel_iop 2>/dev/null || echo 0)
    AGDC_NOW=$(sysctl -n debug.phxagdc 2>/dev/null || echo -1)
    PIPED_NOW=$(sysctl -n debug.nvaccel_heads_piped 2>/dev/null || echo 0)
    echo "M2 stage 2 check: iop=$IOP_NOW agdc=$AGDC_NOW heads_piped=$PIPED_NOW"
    if [ "$IOP_NOW" != 1 ] || [ "$AGDC_NOW" != 1 ] || [ $((PIPED_NOW & 1)) -eq 0 ]; then
        m2_soft_retry "stage 2 display-pipe verification failed" || {
            m2_abort "stage 2 could not establish a stable display pipe"
            exit 0
        }
    fi
    # 只有显示管线和 AGDC 都就绪后，才允许 WindowServer 接入并释放启动 hold。
    all_apps "; WindowServer composites on the 780M (armed only)" '!WindowServer'
    ioreg -rc PhxAMDFB -d2 | grep -q IOFramebufferUserClient && {
        m2_abort "WindowServer opened the panel before the arming"
        exit 0
    }
    before=$(ls "$DR" 2>/dev/null | grep -c '^WindowServer[-_]' || true)
    release
    echo "armed and released at $(date '+%T'); agdc $(sysctl -n debug.phxagdc)"
    # 首次接管后如果 WindowServer 异常，先降档 30 秒再升档；最多做两轮，不重启系统。
    retry=0
    for ((t=0; t<90; t+=5)); do
        sleep 5
        n=$(( $(ls "$DR" 2>/dev/null | grep -c '^WindowServer[-_]' || true) - before ))
        if [ "$n" -ge 3 ]; then
            echo "M2 display warning: WindowServer reports increased by $n in the initial window"
            if [ "$retry" -lt 2 ]; then
                retry=$((retry + 1))
                if m2_soft_retry "initial WindowServer instability, retry $retry"; then
                    before=$(ls "$DR" 2>/dev/null | grep -c '^WindowServer[-_]' || true)
                    t=0
                else
                    m2_abort "display retry did not stabilize WindowServer"
                    exit 0
                fi
            else
                m2_abort "display remained unstable after two runtime retries"
                exit 0
            fi
        fi
    done
    if ! pgrep -qx WindowServer; then
        m2_soft_retry "WindowServer absent after initial display attach" || {
            m2_abort "WindowServer did not return"
            exit 0
        }
    fi
    echo "WindowServer pid $(pgrep -x WindowServer), frames on the panel $(sysctl -n debug.nvaccel_iop_ok)"
else
    release
    all_apps " (WindowServer stays on the firmware framebuffer)" ""
fi
# 不论本次启动是否成功接管，只要持久标记存在，就为下一次人工启动续期。
arm_next_boot
trap - EXIT  # 本次已完成续期，避免退出时重复写入 NVRAM。
rm -f "$MARK"; sync
echo "done $(date '+%T')"

# 常驻观察 WindowServer 报告；连续异常时只降档显示事务，等待后重新升档，不执行系统重启。
watch_hangs() {
    local base n now first=0 last_retry=0
    base=$(ls "$DR" 2>/dev/null | grep -c '^WindowServer-.*\.ips$' || true)
    while sleep 15; do
        n=$(ls "$DR" 2>/dev/null | grep -c '^WindowServer-.*\.ips$' || true)
        [ "$n" -gt "$base" ] || continue
        now=$(date +%s)
        [ "$first" = 0 ] && first=$now
        if [ $((n - base)) -ge 2 ] && [ $((now - last_retry)) -ge 60 ]; then
            echo "$(date '+%F %T') WindowServer instability: runtime downgrade/upgrade; no system reboot"
            last_retry=$now
            if m2_soft_retry "two WindowServer reports within the watch window"; then
                base=$(ls "$DR" 2>/dev/null | grep -c '^WindowServer-.*\.ips$' || true)
                first=0
            else
                echo "display remains in lower mode; a later automatic retry is allowed"
                base=$(ls "$DR" 2>/dev/null | grep -c '^WindowServer-.*\.ips$' || true)
                first=0
            fi
        fi
        [ $((now - first)) -gt 300 ] && { base=$n; first=0; }
    done
}

[ $M2 = 1 ] && watch_hangs
