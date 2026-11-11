# 可选驱动安装说明

本仓库不包含 AMDMicrophone.kext 驱动本体。

scripts/一键部署麦克风.command 只是安装辅助脚本。需要使用者自行从上游取得 AMDMicrophone.kext，放入个人 Downloads 或 Desktop 目录后再执行。

上游项目：https://github.com/qhuyduong/AMDMicrophone

该驱动不属于本 EFI，不得添加到 OpenCore Kernel -> Add。请先阅读上游说明并自行确认兼容性。
