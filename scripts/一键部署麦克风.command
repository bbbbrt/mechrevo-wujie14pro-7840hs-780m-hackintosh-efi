#!/bin/bash
# ========================================================
# 机械革命无界 14 Pro - 用户自备数字麦克风驱动部署脚本
# AMDMicrophone post-boot deployment helper
# ========================================================

clear
echo "=========================================================="
echo "   AMD 数字麦克风部署工具（需用户自备驱动）"
echo "=========================================================="
echo ""

# 1. 获取当前脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEXT_PATH=""
DRIVER_BUNDLE="AMDMicrophone.kext"

# 查找用户自行准备的驱动包
CANDIDATES=(
    "$HOME/Downloads/$DRIVER_BUNDLE"
    "$HOME/Desktop/$DRIVER_BUNDLE"
)

for p in "${CANDIDATES[@]}"; do
    if [ -d "$p" ]; then
        KEXT_PATH="$p"
        break
    fi
done


if [ -z "$KEXT_PATH" ] || [ ! -d "$KEXT_PATH" ]; then
    echo "[!] 错误: 未能在本地找到 $DRIVER_BUNDLE！"
    echo "    本仓库不包含驱动本体。请先从上游自行取得 $DRIVER_BUNDLE，并放到 Downloads 或 Desktop 文件夹。"
    read -p "按回车键退出..."
    exit 1
fi

echo "[1/4] 定位到麦克风驱动: $KEXT_PATH"

# 2. 拷贝到 /Library/Extensions
echo "[2/4] 正在复制到 /Library/Extensions/ (需要管理员密码)..."
sudo cp -R "$KEXT_PATH" /Library/Extensions/

# 3. 修复权限与所有权
echo "[3/4] 正在修复驱动权限 (root:wheel 755)..."
sudo chown -R root:wheel "/Library/Extensions/$DRIVER_BUNDLE"
sudo chmod -R 755 "/Library/Extensions/$DRIVER_BUNDLE"

# 4. 触发内核扩展载入与缓存重建
echo "[4/4] 正在触发内核扩展载入与辅助缓存更新..."
sudo kmutil load -p "/Library/Extensions/$DRIVER_BUNDLE" 2>/dev/null || sudo kextcache -i / 2>/dev/null

echo ""
echo "=========================================================="
echo " [完成] 已将 $DRIVER_BUNDLE 安装到 /Library/Extensions/。"
echo "=========================================================="
echo " 重要的下一步操作提示："
echo " 1. 如果系统弹出【系统扩展已被阻止】提示框："
echo "    请打开：系统设置 -> 隐私与安全性 -> 滑动到底部点击【允许】。"
echo " 2. 按上游说明在系统设置中批准扩展，并重启。"
echo " 3. 不要把此 Kext 加回 OpenCore 的 Kernel -> Add；只在系统启动后使用本脚本。"
echo "=========================================================="
read -p "按回车键退出..."
