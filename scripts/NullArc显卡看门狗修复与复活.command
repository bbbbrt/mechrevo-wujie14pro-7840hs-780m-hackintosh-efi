#!/bin/bash
# ========================================================
# 机械革命无界 14 Pro - NullArc 780M 看门狗复活与清理工具
# NullArc GPU Watchdog Reset & Recovery Tool
# ========================================================

clear
echo "=========================================================="
echo "    NullArc 780M 显卡加速死锁排查与一键复活工具"
echo "=========================================================="
echo "适用场景: 开启显卡后死机/黑屏/连环重启，或被看门狗安全回退"
echo "=========================================================="
echo ""

echo "[1/4] 清理 WindowServer 遗留的显示器与分辨率脏配置..."
sudo rm -f /Library/Preferences/com.apple.windowserver.displays.plist
rm -f ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist

echo "[2/4] 清空旧崩溃日志与看门狗计数器..."
sudo rm -f /Library/Logs/DiagnosticReports/WindowServer*
sudo rm -f /var/db/phxboot.pending
sudo rm -f /Users/Shared/gpu/hang-reboots

echo "[3/4] 清除 BetterDisplay 潜在冲突配置文件..."
rm -rf ~/Library/Application\ Support/BetterDisplay* 2>/dev/null
rm -rf ~/Library/Preferences/pro.betterdisplay* 2>/dev/null

echo "[4/4] 解除 NullArc 禁用锁 (激活 780M 硬件加速)..."
sudo rm -f /Users/Shared/gpu/phxboot-off

echo ""
echo "=========================================================="
echo " [完成] 复活环境清理完毕！"
echo " 提示: 请务必确保【自动登录】处于开启状态！"
echo "=========================================================="
echo ""
read -p "是否立即重启电脑生效？(y/n): " confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    sudo reboot
else
    echo "请稍后手动重启。"
fi
