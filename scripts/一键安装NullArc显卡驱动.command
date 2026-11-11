#!/bin/bash
# 无界 14 Pro - AMD Radeon 780M / NullArc 安装辅助脚本
set -euo pipefail
clear
echo "请先开启自动登录，并准备好可恢复的启动 U 盘和 EFI 备份。"
echo "NullArc 当前为 Alpha 预发布版本，请先阅读上游说明及许可。"
read -p "确认后按回车继续..."
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT
ZIP_PATH=""
for p in /Volumes/*/nullarc-0.4.0-alpha.zip "$HOME/Downloads/nullarc-0.4.0-alpha.zip" "$HOME/Desktop/nullarc-0.4.0-alpha.zip"; do
    if [ -f "$p" ]; then ZIP_PATH="$p"; break; fi
done
if [ -z "$ZIP_PATH" ]; then
    echo "未找到 nullarc-0.4.0-alpha.zip，请从 https://github.com/luuumi-dev/nullarc/releases 下载并放入 Downloads。"
    exit 1
fi
unzip -q "$ZIP_PATH" -d "$TMP_DIR"
INSTALL_SCRIPT="$(find "$TMP_DIR" -type f -name install.sh -print -quit)"
if [ -z "$INSTALL_SCRIPT" ]; then echo "安装包中没有 install.sh，已停止。"; exit 1; fi
cd "$(dirname "$INSTALL_SCRIPT")"
sudo ./install.sh --windowserver
echo "安装程序已执行，请按 NullArc 上游说明完成后续步骤及重启。"
