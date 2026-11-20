# NullArc Radeon 780M 加速部署与故障恢复指南

> 最近一次本机实测：macOS Tahoe 26.7.3（25G342），2026-11-19。NullArc 已完成一次干净启动后的 780M 内屏接管。此结论仅适用于该机和该次启动。

## 当前自动接管链路

1. OpenCore 加载 PhxBringup.kext。
2. 系统启动后，launchd 按 local.phxboot 标签运行 phxboot.sh。
3. phxboot.sh 检查 Xcode 首次启动状态，未完成时不向 GPU 写入固件或寄存器。
4. 每个 macOS 启动周期只完整初始化一次，避免重复销毁 PSP ring 并重新加载 SMU。
5. GPU 队列测试和 Metal 冒烟测试通过后，才开启显示事务与 AGDC，确认 heads_piped 后释放 PhxAMDFB hold。
6. WindowServer 初始阶段若不稳定，脚本有限次运行时降档和重试；失败时保留本次系统启动，不自动重启整机。

部署脚本快照和 LaunchDaemon 位于 scripts/nullarc-runtime/。完整驱动及固件依赖不包含在本 EFI 发布包中，必须遵循 NullArc 上游安装和许可说明。

上游项目：https://github.com/luuumi-dev/nullarc

## 安装前提

- 先备份可启动 EFI，并准备恢复 U 盘。
- 按 NullArc 上游文档安装与当前 macOS 版本匹配的组件。
- 需要完整 Xcode 完成首次启动。检查命令：xcodebuild -checkFirstLaunchStatus。
- 如果尚未接受 Xcode 许可，可在本机终端执行 sudo xcodebuild -license accept，再执行 sudo xcodebuild -runFirstLaunch；完成后重新检查状态。
- 确认 /Library/LaunchDaemons/local.phxboot.plist 指向 /Users/Shared/gpu/phxboot.sh。

## 只读诊断

查看当前驱动和内屏状态：

    /Users/Shared/gpu/recover.sh --status

检查 Xcode：

    xcodebuild -checkFirstLaunchStatus

查看启动日志：

    tail -n 100 /var/log/phxboot.log

查看完整初始化日志：

    tail -n 100 /Users/Shared/gpu/phxboot-detail.log

## 故障时的处理原则

- 如果日志提示 Xcode first-launch 未完成，先修复 Xcode 环境；不要反复重跑 GPU 初始化。
- 同一次 macOS 启动周期内，phxboot.sh 会拒绝第二次完整初始化。
- 如果 SMU / PSP / MES 没有响应，停止重复发送寄存器或固件命令；保留日志，评估是否需要正常冷启动复位。
- 不要手动运行旧版恢复脚本中的清理命令，不要删除 WindowServer 崩溃日志来掩盖问题。
- 不要用 killall -9 WindowServer 作为常规恢复方式。
- 不要把 shutdown / reboot 放入自动 watchdog。当前 watchdog.py 只终止本次初始化进程树。

## Kill switch 与持久启动标记

- /Users/Shared/gpu/phxboot-off：存在时停止自动接管。
- /Users/Shared/gpu/phxboot-m2.keep：存在时在接管成功或失败后为下一次正常启动续期。
- /var/db/phxboot.attempted-boot：当前 macOS 启动周期的一次性尝试标记；下一次启动会有新的 kern.boottime，不会永久阻塞。

不要为了“复活”而随意删除标记或清空诊断文件。先读取 recover.sh --status 和日志，确认状态后再决定是否变更。

## 当前已知限制

- 本机 macOS 26.7.3 本次接管成功，不保证其他固件或 macOS build 一样。
- AirDrop 需要在 26.7.3 上再次双向测试。
- 睡眠 / 唤醒尚未确认；此前观察到 kPMPCIUnsupported。
- 触控板输入问题与 NullArc 无直接因果证据，请按独立的触控板诊断记录处理。
