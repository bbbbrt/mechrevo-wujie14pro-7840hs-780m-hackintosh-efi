# 第三方组件鸣谢与许可

本仓库根目录的 MIT 许可证只覆盖本项目原创的文档、辅助脚本与配置整理，不覆盖第三方驱动或二进制文件。所有第三方组件仍遵循各自上游许可证。

| 项目 | 用途 | 上游 |
|---|---|---|
| OpenCore / Acidanthera | UEFI 引导与相关组件 | https://github.com/acidanthera |
| NullArc / PhxBringup | 本仓库中的 PhxBringup.kext 来自 NullArc 的 src/phxbringup；上游标注 MIT 或 GPL-2.0-only（任选其一） | https://github.com/luuumi-dev/nullarc |
| AMDMicrophone | AMD ACP 数字麦克风项目（仅鸣谢；本仓库不包含或分发 Kext 本体） | https://github.com/qhuyduong/AMDMicrophone |
| VoodooI2C | I2C 触控板支持 | https://github.com/VoodooI2C/VoodooI2C |
| OpenIntelWireless | Intel 无线网卡支持 | https://github.com/OpenIntelWireless |
| AMD Vanilla | AMD 平台内核补丁 | https://github.com/AMD-OSX/AMD_Vanilla |

## 许可注意事项

- NullArc 上游将 src/phxbringup、tools/phxctl 和多数自有代码列为 MIT 或 GPL-2.0-only（任选其一）；本仓库只分发 PhxBringup.kext，不包含 NullArc 完整用户态驱动包。
- NullArc 的 src/phxaccel、src/nmplugin 与 tools/nvmtl-patches 衍生自 NullMoth，受 PolyForm Noncommercial 1.0.0 限制；这些组件不在本仓库中。若另行下载完整 NullArc 发行包，必须遵守其非商业使用限制及上游要求的版权声明。
- NullArc 当前为 Alpha 预发布版本。请以其上游 LICENSE、LICENSES/ 与 THIRD_PARTY_NOTICES.md 为准。
- AMDMicrophone.kext 归 qhuyduong 上游项目所有。本仓库仅致谢该项目，并保留一个需要用户自备驱动文件的可选部署脚本；不分发该 Kext，不声称拥有驱动著作权。
- Apple 专有的 AppleHDA.kext 文件不在本仓库分发。
- 其他 Kext、UEFI 驱动和二进制文件均保留各自上游权利与许可证。再分发、修改或商业使用前，请逐项核对上游许可。

本项目按“现状”提供，不作任何明示或默示保证。使用 Hackintosh 可能涉及 Apple 软件许可条款限制，用户需自行确认适用的法律与许可要求。
