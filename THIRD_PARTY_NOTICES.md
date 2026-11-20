# 第三方组件鸣谢与许可

本仓库根目录的 MIT 许可证只覆盖本项目原创的文档、辅助脚本与配置整理，不覆盖第三方驱动或二进制文件。所有第三方组件仍遵循各自上游许可证。

| 项目 | 用途 / 版本 / 许可 | 上游 |
|---|---|---|
| OpenCore / Acidanthera | UEFI 引导与相关组件 | https://github.com/acidanthera |
| [NullArc / PhxBringup](https://github.com/luuumi-dev/nullarc) | 本仓库中的 PhxBringup.kext 来自上游 src/phxbringup；上游标注 MIT 或 GPL-2.0-only（任选其一） | [上游仓库](https://github.com/luuumi-dev/nullarc) |
| [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone) | AMD ACP 内置数字麦克风；EFI 版本 1.0.0；MIT | [上游仓库](https://github.com/qhuyduong/AMDMicrophone) |
| VoodooI2C | I2C 触控板支持 | https://github.com/VoodooI2C/VoodooI2C |
| ForbiddenItlwm | Intel AX200 Wi-Fi / AWDL；0.6.0-beta.2；GPL-2.0；AirDrop 在 macOS 26.7.3 实测可用 | https://github.com/retropineaple/ForbiddenItlwm/tree/v0.6.0-beta.2 |
| OpenIntelWireless | Intel 无线网卡支持 | https://github.com/OpenIntelWireless |
| AMD Vanilla | AMD 平台内核补丁 | https://github.com/AMD-OSX/AMD_Vanilla |

## 许可注意事项

- [NullArc](https://github.com/luuumi-dev/nullarc) 上游将 src/phxbringup、tools/phxctl 和多数自有代码列为 MIT 或 GPL-2.0-only（任选其一）；本仓库只分发 PhxBringup.kext，不包含 [NullArc](https://github.com/luuumi-dev/nullarc) 完整用户态驱动包。
- [NullArc](https://github.com/luuumi-dev/nullarc) 的 src/phxaccel、src/nmplugin 与 tools/nvmtl-patches 衍生自 NullMoth，受 PolyForm Noncommercial 1.0.0 限制；这些组件不在本仓库中。若另行下载完整 [NullArc](https://github.com/luuumi-dev/nullarc) 发行包，必须遵守其非商业使用限制及上游要求的版权声明。
- [NullArc](https://github.com/luuumi-dev/nullarc) 当前版本及许可状态请以上游 LICENSE、LICENSES/ 与 THIRD_PARTY_NOTICES.md 为准。
- [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone) 由上游按 MIT 许可发布；对应许可证文本见 licenses/third-party/AMDMicrophone-MIT.txt。
- Apple 专有的 AppleHDA.kext 文件不在本仓库分发。
- 其他 Kext、UEFI 驱动和二进制文件均保留各自上游权利与许可证。再分发、修改或商业使用前，请逐项核对上游许可。

本项目按“现状”提供，不作任何明示或默示保证。使用 Hackintosh 可能涉及 Apple 软件许可条款限制，用户需自行确认适用的法律与许可要求。


## 本机运行时文件说明

- scripts/nullarc-runtime/ 收录本机部署的 NullArc 启动、诊断和 LaunchDaemon 脚本快照；完整 NullArc 用户态组件、phxctl / mesboot / mtlprobe 二进制及 AMDGPU firmware 不在本仓库分发。
- AMDGPU firmware 的文件名与本机 SHA-256 记录在 scripts/nullarc-runtime/FIRMWARE-SHA256.txt；获取和再分发前应核对 linux-firmware 对应文件的许可证。
- MechrevoFan、VoodooHDA_BL、XhciNudge 等本机定制组件应在公开发布前逐项核实源码来源和再分发许可。

<!-- AX200-BLUETOOTH-THIRD-PARTY-20261119 -->
## Intel AX200 蓝牙/Wi-Fi 更新组件（2026-11-19）

| 组件 | 用途 | 版本 | 许可证 | 上游源码 |
|---|---|---:|---|---|
| ForbiddenItlwm | AX200 Wi-Fi / AWDL | 0.6.0-beta.2 Tahoe | GPL-2.0 | https://github.com/retropineaple/ForbiddenItlwm/tree/v0.6.0-beta.2 |
| BTLEAdvFixup | Intel BLE 广播与配对兼容修复 | 0.9.3 Tahoe | GPL-2.0 | https://github.com/retropineaple/ForbiddenItlwm/tree/v0.6.0-beta.2 |
| IntelBluetoothFirmware | AX200 蓝牙固件加载 | 2.5.2-dlc-fix | GPL-3.0 | https://github.com/emulatorchen/IntelBluetoothFirmware/tree/2.5.2-dlc-fix |

本仓库单独分发上述第三方 kext 时，同时保留对应上游源码标签压缩包、许可证与版权声明。不要将这些第三方组件误标为本项目 MIT 许可。

## XhciNudge

- **上游项目**：[MonkaKokosowa/XhciNudge](https://github.com/MonkaKokosowa/XhciNudge)
- **作者**：Monika Maka
- **版本**：1.0.0
- **用途**：针对 AMD XHCI USB 控制器输入延迟问题的辅助组件
- **许可证**：MIT；许可证文本见 `licenses/third-party/XhciNudge-MIT.txt`
- **再分发说明**：本仓库保留上游项目链接与 MIT 许可证文本；当前二进制是否与上游发布构建完全一致，仍需在正式发布前核对。

## 自定义组件与发布审查状态

- `MechrevoFan.kext` 为本项目自写组件，因实测效果不理想已在 `config.plist` 中设为 `Enabled = false`。文件仍保留在 EFI 目录中；后续稳定发布前可考虑移除，本次不擅自删除。
- `VoodooHDA_BL.kext` 当前仍在配置中启用。其定制二进制的来源、构建过程及再分发许可链尚未完成核验；核验完成前，不应将包含该文件的压缩包标记为可公开再分发的正式 Release。
