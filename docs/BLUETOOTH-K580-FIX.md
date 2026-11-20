# Intel AX200 蓝牙与 Logitech K580 修复记录

> 日期：2026-11-19
> 设备：机械革命无界 14 Pro，AMD Ryzen 7 7840HS / Radeon 780M
> 系统：macOS Tahoe 26.7.3（Build 25G342，Darwin 25.6.0）
> 蓝牙设备：Intel AX200 蓝牙 USB 控制器（VID:PID 8087:0029）
> 外设：Logitech K580 蓝牙键盘

## 1. 故障现象与诊断

连接 K580 时，菜单栏蓝牙图标会短暂关闭、随后再次开启。系统日志显示 `bluetoothd`（蓝牙后台服务）多次退出，`launchd`（系统服务管理器）随后重新拉起它。

故障期间捕获到的代表性日志包括：

- `Invalid chipset 0`
- `Failed to read local Fast LE Connection data`
- HCI（主机控制器接口）命令完成事件异常
- `bluetoothd` 以 `exit(1)` 退出并被系统重新启动

这组日志表明问题发生在蓝牙控制器初始化、固件/协议栈交接阶段，不是单纯的 K580 配对记录损坏。仅凭日志不能把所有退出都归因于某一个 kext（内核扩展），因此本次采用经过上游实机验证的配套版本升级，而不是盲目删除配对信息或启用旧补丁。

## 2. 上游问题与修复依据

- [ForbiddenItlwm 0.6.0-beta.2 发布说明](https://github.com/retropineaple/ForbiddenItlwm/releases/tag/v0.6.0-beta.2)包含 BTLEAdvFixup 0.9.3。
- 上游 Issue [#71](https://github.com/retropineaple/ForbiddenItlwm/issues/71)记录了 AX200（蓝牙 USB ID 同为 `8087:0029`）在 Tahoe 26.7.3 上无法完成 Logitech BLE 外设配对的问题。维护者确认 0.9.2 的安全修正误将 LE（低功耗蓝牙）数据长度修复关闭，0.9.3 恢复该路径；报告者随后确认配对成功。
- 上游 Issue [#62](https://github.com/retropineaple/ForbiddenItlwm/issues/62)记录了旧版 BTLEAdvFixup 的长期运行稳定性问题；0.9.2 之后的版本包含相关安全修正。

本机使用的 K580 与上游报告的 Logitech BLE 鼠标并非同一外设，但它们都走 BLE 配对流程；因此上游 AX200 / Tahoe 26.7.3 的成功记录是有针对性的参考，不代表所有键盘均保证兼容。

## 3. 本次实际升级

| 组件 | 升级前 | 升级后 | 说明 |
|---|---:|---:|---|
| IntelBluetoothFirmware | 2.4.0 | **2.5.2** | 使用 emulatorchen 的 2.5.2-dlc-fix Tahoe 适配包 |
| BTLEAdvFixup | 0.9.1 | **0.9.3** | 修复 BLE 键鼠配对路径 |
| ForbiddenItlwm | 0.5.4 | **0.6.0-beta.2** | 与 BTLEAdvFixup 0.9.3 配套 |
| BlueToolFixup | 2.7.2 | 2.7.2（不变） | 保留 |
| Lilu | 原版本 | 原版本（不变） | 保留 |

配置同步原则：

- `AirportItlwm.kext` 设为禁用，避免与 `ForbiddenItlwm.kext` 同时加载。
- `IntelBluetoothFirmware.kext`、`BlueToolFixup.kext`、`BTLEAdvFixup.kext`、`ForbiddenItlwm.kext` 按当前实测配置启用。
- `IntelBTPatcher.kext` 保持禁用，不重新启用旧的蓝牙补丁。
- 保留当前完整的 `-btleadv` 与 Itlwm/AWDL 启动参数，不清空原有其他启动参数。

## 4. 重启后的实机验证

用户实机确认：重启后蓝牙恢复正常，Type-C 转 HDMI 输出也恢复可用。

重启后的只读检查结果：

- macOS 蓝牙状态：`State: On`
- `bluetoothd` 持续运行，未再出现启动后立即退出的循环
- 实际加载版本：IntelBluetoothFirmware 2.5.2、BTLEAdvFixup 0.9.3、ForbiddenItlwm 0.6.0、BlueToolFixup 2.7.2
- I/O Registry（输入输出注册表）读到 `BTLEAdvEventPipes = 1`、`BTLEAdvHookRouted = 1`、`BTLEAdvPipeHooks = 5`

用户已确认重启后蓝牙功能恢复。后续若做更深入的 BLE 配对诊断，可在 K580 配对时运行：

```bash
ioreg -l -w0 -d1 | grep '"BTLEAdv'
```

重点观察 `BTLEAdvEventPipes` 与 `BTLEAdvLengthRewrites` 是否出现并递增。

## 5. 配置与回滚

- 本次没有启用 `IntelBTPatcher.kext`，也没有更改 SMBIOS（系统机型身份）三码、显卡驱动或显示器模式配置。
- 原始 kext、config.plist 与 EFI 分区镜像均已在本机另行备份；备份不放入公开仓库。
- 本更新包供 Windows 下同步 Git 仓库使用，不会自动覆盖 U 盘根目录的启动 EFI。
- 若要回滚，只恢复备份中的 `IntelBluetoothFirmware.kext`、`BTLEAdvFixup.kext`、`ForbiddenItlwm.kext` 及对应 config.plist；不要只回滚其中一项而保留不匹配的驱动组合。

## 6. 上游来源与许可证

- ForbiddenItlwm / BTLEAdvFixup：GPL-2.0，上游源码标签 `v0.6.0-beta.2`
  https://github.com/retropineaple/ForbiddenItlwm/tree/v0.6.0-beta.2
- IntelBluetoothFirmware 2.5.2-dlc-fix：GPL-3.0，上游源码标签 `2.5.2-dlc-fix`
  https://github.com/emulatorchen/IntelBluetoothFirmware/tree/2.5.2-dlc-fix

对应源码压缩包和许可证文本随本次 U 盘更新包提供，供后续 GitHub 发布时一并保留。
