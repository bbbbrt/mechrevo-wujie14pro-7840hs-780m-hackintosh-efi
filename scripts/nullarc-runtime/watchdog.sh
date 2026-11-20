#!/bin/bash
# 中文注释：NullArc 启动脚本共用的、可按 PID 精确取消的超时看门狗。
G=/Users/Shared/gpu
PHX_WATCHDOG_PID_FILE=/var/run/nullarc-gpu-watchdog.pid
PHX_WATCHDOG_PID=""

phx_watchdog_cancel() {
    local pid cmd current_pid
    current_pid="${PHX_WATCHDOG_PID:-}"

    if [ ! -f "$PHX_WATCHDOG_PID_FILE" ]; then
        PHX_WATCHDOG_PID=""
        return 0
    fi

    pid="$(/bin/cat "$PHX_WATCHDOG_PID_FILE" 2>/dev/null || true)"
    case "$pid" in
        ''|*[!0-9]*)
            /bin/rm -f "$PHX_WATCHDOG_PID_FILE"
            PHX_WATCHDOG_PID=""
            echo "看门狗 PID 文件无效，已清理"
            return 0
            ;;
    esac

    cmd="$(/bin/ps -p "$pid" -o command= 2>/dev/null || true)"
    if [ -n "$cmd" ] && [[ "$cmd" == *"$G/watchdog.py"* ]]; then
        /bin/kill -TERM "$pid" 2>/dev/null || true
        if [ "$current_pid" = "$pid" ]; then
            wait "$pid" 2>/dev/null || true
        fi
        echo "看门狗已取消（PID ${pid}）"
    else
        echo "看门狗进程不存在或 PID 已被复用，未触碰其他进程"
    fi

    /bin/rm -f "$PHX_WATCHDOG_PID_FILE"
    PHX_WATCHDOG_PID=""
}
phx_watchdog_start() {
    local seconds="${1:-180}"

    case "$seconds" in
        ''|*[!0-9]*)
            echo "看门狗时限必须是整数秒" >&2
            return 2
            ;;
    esac

    if [ "$seconds" -lt 1 ] || [ "$seconds" -gt 1800 ]; then
        echo "看门狗时限必须在 1 到 1800 秒之间" >&2
        return 2
    fi

    phx_watchdog_cancel >/dev/null 2>&1 || true

    /usr/bin/python3 "$G/watchdog.py" "$seconds" >/dev/null 2>&1 &
    PHX_WATCHDOG_PID=$!
    printf '%s\n' "$PHX_WATCHDOG_PID" > "$PHX_WATCHDOG_PID_FILE"
    /bin/chmod 0600 "$PHX_WATCHDOG_PID_FILE"

    /bin/sleep 0.1
    if ! /bin/kill -0 "$PHX_WATCHDOG_PID" 2>/dev/null; then
        /bin/rm -f "$PHX_WATCHDOG_PID_FILE"
        echo "看门狗启动失败" >&2
        return 1
    fi

    echo "看门狗已启动（PID ${PHX_WATCHDOG_PID:-未知}，${seconds} 秒）"
}
