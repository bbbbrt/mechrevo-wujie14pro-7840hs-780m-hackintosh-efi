#!/bin/bash
# NullArc GPU 恢复工具：默认只读取状态，不自动重新武装下一次启动。
set -u
G=/Users/Shared/gpu

read_sysctl() {
    local value
    value=$(sysctl -n "$1" 2>/dev/null) || value="不可用"
    printf '%s' "$value"
}

show_status() {
    local fb_class nmx fb_mode iop headless frames boot_flag marker
    fb_class=$(ioreg -r -c IOFramebuffer -d0 2>/dev/null | sed -n 's/.*<class \([^,>]*\).*/\1/p' | head -n 1)
    [ -n "$fb_class" ] || fb_class="未识别"
    if ioreg -r -c NMXAccel -d0 2>/dev/null | grep -q NMXAccel; then nmx="已注册"; else nmx="未注册"; fi
    fb_mode=$(read_sysctl debug.nvaccelfb)
    iop=$(read_sysctl debug.nvaccel_iop)
    headless=$(read_sysctl debug.nmxaccel_headless)
    frames=$(read_sysctl debug.nvaccel_iop_ok)
    boot_flag=$(nvram phxfb-boot 2>/dev/null | sed 's/^[^=]*=//' || true)
    [ -n "$boot_flag" ] || boot_flag="未设置"

    echo "=== NullArc 当前状态 ==="
    printf 'PhxBringup：'; ioreg -l 2>/dev/null | grep -q '"phx-build"' && echo "已加载" || echo "未检测到"
    printf 'NMXAccel：%s\n' "$nmx"
    printf '当前内屏帧缓冲：%s\n' "$fb_class"
    printf 'debug.nvaccelfb：%s\n' "$fb_mode"
    printf 'debug.nvaccel_iop：%s\n' "$iop"
    printf 'debug.nmxaccel_headless：%s\n' "$headless"
    printf 'debug.nvaccel_iop_ok：%s\n' "$frames"
    printf 'phxfb-boot：%s\n' "$boot_flag"
    for marker in phxboot-m2 phxboot-off; do
        if [ -e "$G/$marker" ]; then echo "${marker}：存在"; else echo "${marker}：不存在"; fi
    done
    if [ -e /var/db/phxboot.pending ]; then echo "phxboot.pending：存在"; else echo "phxboot.pending：不存在"; fi
    echo "========================"
}

restart_windowserver() {
    local fb_info fb_mode iop headless frames
    if [ "$(id -u)" -ne 0 ]; then
        echo "需要管理员权限：请使用 sudo gpu-recover -f" >&2
        exit 1
    fi
    fb_info=$(ioreg -r -c IOFramebuffer -d0 2>/dev/null || true)
    fb_mode=$(read_sysctl debug.nvaccelfb)
    iop=$(read_sysctl debug.nvaccel_iop)
    headless=$(read_sysctl debug.nmxaccel_headless)
    frames=$(read_sysctl debug.nvaccel_iop_ok)

    if ! printf '%s\n' "$fb_info" | grep -q 'class PhxAMDFB'; then
        echo "拒绝重启 WindowServer：当前内屏不是 PhxAMDFB，仍使用固件帧缓冲。"
        echo "此时重启桌面不会启用 NullArc 显示加速，也不会修复下一次启动。"
        show_status
        exit 2
    fi
    if [ "$fb_mode" != "1" ] || [ "$iop" != "1" ] || [ "$headless" != "0" ] || ! [[ "$frames" =~ ^[0-9]+$ ]] || [ "$frames" -le 0 ]; then
        echo "拒绝重启 WindowServer：显示加速、非无头模式或有效帧计数未通过检查。"
        show_status
        exit 2
    fi

    echo "检查通过：PhxAMDFB 已接管内屏，GPU 帧计数有效。"
    echo "现在仅重启 WindowServer；不会写入 NVRAM、创建启动标记或修改 Metal 允许列表。"
    killall -9 WindowServer
}

case "${1:---status}" in
    --status|-s) show_status ;;
    --restart-ws|-f) restart_windowserver ;;
    --help|-h)
        echo "用法：gpu-recover [--status | --restart-ws]"
        echo "  --status      只读取当前驱动与启动标记状态（默认）"
        echo "  --restart-ws  仅在 PhxAMDFB 与帧计数确认正常时重启桌面"
        echo "  -f            --restart-ws 的兼容写法"
        echo "此工具不再自动设置 phxfb-boot，也不再修改 GPU 启动标记。"
        ;;
    *) echo "未知参数：$1；运行 gpu-recover --help 查看用法。" >&2; exit 64 ;;
esac
