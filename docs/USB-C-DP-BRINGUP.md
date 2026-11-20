# USB-C DisplayPort Alt Mode 外接显示实测记录

> 日期：2026-11-20
> 设备：机械革命无界 14 Pro（Ryzen 7 7840HS / Radeon 780M）
> 系统：macOS Tahoe 26.7.3（Darwin 25.6.0）
> 外接显示器：27C1U-D
> 结论范围：本机 USB-C DP Alt Mode 两通道 HBR2 实测成功。

## 1. 实测结果

- USB-C 视频输出连接外接显示器，已实际点亮并进入桌面。
- 外接显示器：2560×1440 @ 60Hz。
- 内置屏幕：2880×1800 @ 120Hz。
- DP 链路训练日志显示 LINK UP；训练参数记录为 VS2 / PE1。
- 当前成功模式为 DP Alt Mode 两通道 HBR2，每通道 5.4 Gbit/s。
- 该结果仅代表本机本次组合，不保证所有显示器、扩展坞和转接器兼容。

## 2. NullArc / 显示管线背景

- 上游项目：https://github.com/QiRanChenk/nullarc
- 相关上游改动：hdmi-fb2，commit 73fe58b；对应上游 issue：#27。
- phxfb2=1 路径创建第二个 framebuffer（帧缓冲区）。
- 第二 framebuffer 使用 IOFBDependentIndex=1；记录的 VRAM offset 为 0x6000000，对应 DCN pipe 1。
- 本机 PhxAccel 调试涉及：
  - src/phxaccel/accel/phxfb.cpp
  - src/phxaccel/accel/nvrm-accel.cpp
  - src/phxaccel/accel/phxagdc.cpp
- 本机配置保留已加入的 1440×900 HiDPI 模式，后续修改应保留并回归验证。

## 3. 本机诊断资料

- VBIOS 曾从 Ubuntu 的 /sys/kernel/debug/dri/0000:63:00.0/amdgpu_vbios 导出。
- 文件大小：12 KiB；ATOMBIOS 版本：022.012.000.016.000001。
- Board：113-PHXGENERIC-001。
- SHA-256：b56cad281f5060f1469dac8b3f9f01bb7f073c9b89b30da2cc7f9a9894158145。
- 该 VBIOS 属于本机诊断材料，不可作为其他设备的通用固件，也不可据此指导刷写。

## 4. 驱动部署与保活记录

- PhxAccel 新版 kext UUID：C6708A86-6D3D-393C-9952-FEC012400189。
- 更新后已重新生成并发布 Auxiliary Kernel Collection（辅助内核集合）。
- 本机辅助目录：/Users/Shared/gpu/dp-lab。
- LaunchDaemon（启动守护项）：/Library/LaunchDaemons/local.usbc-dp.plist。
- 检测脚本：/Users/Shared/gpu/dp-lab/dp-watch.sh。
- 日志：/Users/Shared/dp-watch.log。
- 以上是本机部署记录，不是可直接复制到其他机器的通用安装包。

## 5. 追加验证：USB-C 一线连与 QGeeM Type-C 转 HDMI（2026-11-20）

- 转接设备：QGeeM USB-C 多功能扩展坞，HDMI 输出。
- 初始状态：Mac 连接扩展坞时未检测到外接显示器，DP 热插拔检测与 EDID 读取均未进入正常链路流程；该状态下不能据此断言扩展坞损坏。
- 更新当前 EFI 中的显卡/显示配置并重启后，用户再次确认 Type-C 转 HDMI 输出正常；USB-C 一线连显示器也已确认可用。
- 本次没有记录该 HDMI 转接输出的具体分辨率、刷新率，因此不把 DP 直连的 2560×1440 @ 60Hz 数据套用到 HDMI 转接。
- 目前可记录为：本机 QGeeM USB-C 转 HDMI 已实机点亮；其他型号扩展坞、长时间稳定性、热插拔及睡眠唤醒仍未验证。
- 本轮没有刷写或修改 VBIOS；VBIOS 仍仅作为诊断资料。

## 6. 尚未验证的项目

1. DP 四通道 HBR2 / HBR3 模式。
2. DP 输出同时保持 USB 3.x 高速数据传输。
3. 长时间连续运行稳定性。
4. 合盖、睡眠、唤醒及热插拔后的恢复。
5. QGeeM 以外其他 USB-C 转 HDMI 转接器兼容性，以及本次 HDMI 输出的精确分辨率/刷新率。

## 7. 安全与维护建议

- 保留当前已验证 EFI 和 kext 版本备份。
- 不要为了新增显示模式直接覆盖已工作的 EFI。
- 每次只调整一个变量，并记录启动参数、显示器 EDID、链路训练日志与实际分辨率。
- 不要公开发布 SMBIOS 序列号、MLB、UUID、ROM、账户凭据或未经脱敏的机器专属日志。
