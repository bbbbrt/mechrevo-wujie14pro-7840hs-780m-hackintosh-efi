#!/bin/bash
# NullArc 状态检查工具：只读取当前状态，不清日志、不删标记、不重启。
set -euo pipefail
GPU_ROOT=/Users/Shared/gpu
if [[ ! -x "$GPU_ROOT/recover.sh" ]]; then
    echo "没有找到当前 NullArc recover.sh：$GPU_ROOT/recover.sh"
    echo "请先按仓库 docs/NullArc显卡加速恢复指南.md 检查部署状态。"
    read -r -p "按回车退出。"
    exit 1
fi
echo "=== NullArc 只读状态检查 ==="
"$GPU_ROOT/recover.sh" --status
echo
if command -v xcodebuild >/dev/null 2>&1; then
    if xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
        echo "Xcode 首次启动状态：通过"
    else
        echo "Xcode 首次启动状态：未完成"
        echo "请在终端执行：sudo xcodebuild -license accept"
        echo "然后执行：sudo xcodebuild -runFirstLaunch"
    fi
else
    echo "未找到 xcodebuild；NullArc 启动脚本将跳过 GPU 初始化。"
fi
echo
echo "本工具只读，不会删除诊断日志、修改 NVRAM、重启 WindowServer 或重启整机。"
read -r -p "按回车退出。"
