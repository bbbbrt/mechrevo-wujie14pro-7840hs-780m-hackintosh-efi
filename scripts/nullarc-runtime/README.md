# NullArc 实机运行时脚本快照

本目录是 2026-11-19 在机械革命无界 14 Pro / Ryzen 7 7840HS / Radeon 780M 上实际部署的脚本和 LaunchDaemon 配置快照。它不是完整安装包，也不应直接覆盖其他机器的 GPU 运行环境。

## 自动启动链路

- LaunchDaemon 标签为 local.phxboot，配置文件为 local.phxboot.plist。
- 开机时由 launchd 调用 /Users/Shared/gpu/phxboot.sh。
- phxboot.sh 首先检查 Xcode 首次启动状态；未完成时跳过 GPU 初始化。
- 每个 macOS 启动周期只允许一次完整初始化，避免重复销毁 PSP 环并重刷 SMU。
- GPU 队列、Metal 测试、显示管线通过后，才释放 PhxAMDFB 启动 hold。
- 显示异常采用运行时降档与有限重试；失败时不自动重启整机。
- watchdog.py 只终止本次初始化进程树，不负责重启整机。

## 运行依赖

完整运行环境还需要 NullArc 上游组件、按本机编译的 phxctl / mesboot / mtlprobe，以及 AMDGPU firmware。出于许可和可复现性考虑，本目录不分发这些二进制或固件文件；固件文件名与 SHA-256 记录在 FIRMWARE-SHA256.txt。

NullArc 上游：https://github.com/luuumi-dev/nullarc

## 常用只读检查

- 检查首次启动状态：xcodebuild -checkFirstLaunchStatus
- 查看 NullArc 当前状态：/Users/Shared/gpu/recover.sh --status
- 查看启动日志：tail -n 100 /var/log/phxboot.log
- 查看详细初始化日志：tail -n 100 /Users/Shared/gpu/phxboot-detail.log

不要在同一次 macOS 启动周期里反复手动运行 bringup5.sh 或 phxboot.sh。初始化失败后先检查日志和启动状态；不要直接重复向 GPU 提交固件或寄存器命令。
