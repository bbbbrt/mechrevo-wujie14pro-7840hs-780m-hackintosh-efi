# 第三方组件鸣谢与许可

本仓库根目录的 MIT 许可证只覆盖本项目原创的文档、辅助脚本与配置整理，不覆盖第三方驱动或二进制文件。所有第三方组件仍遵循各自上游许可证。

| 项目 | 用途 | 上游 |
|---|---|---|
| OpenCore / Acidanthera | UEFI 引导与相关组件 | https://github.com/acidanthera |
| [NullArc / PhxBringup](https://github.com/luuumi-dev/nullarc) | 本仓库中的 PhxBringup.kext 来自上游 src/phxbringup；上游标注 MIT 或 GPL-2.0-only（任选其一） | [上游仓库](https://github.com/luuumi-dev/nullarc) |
| [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone) | AMD ACP 内置数字麦克风上游项目（鸣谢） | [上游仓库](https://github.com/qhuyduong/AMDMicrophone) |
| VoodooI2C | I2C 触控板支持 | https://github.com/VoodooI2C/VoodooI2C |
| OpenIntelWireless | Intel 无线网卡支持 | https://github.com/OpenIntelWireless |
| AMD Vanilla | AMD 平台内核补丁 | https://github.com/AMD-OSX/AMD_Vanilla |

## 许可注意事项

- [NullArc](https://github.com/luuumi-dev/nullarc) 上游将 src/phxbringup、tools/phxctl 和多数自有代码列为 MIT 或 GPL-2.0-only（任选其一）；本仓库只分发 PhxBringup.kext，不包含 [NullArc](https://github.com/luuumi-dev/nullarc) 完整用户态驱动包。
- [NullArc](https://github.com/luuumi-dev/nullarc) 的 src/phxaccel、src/nmplugin 与 tools/nvmtl-patches 衍生自 NullMoth，受 PolyForm Noncommercial 1.0.0 限制；这些组件不在本仓库中。若另行下载完整 [NullArc](https://github.com/luuumi-dev/nullarc) 发行包，必须遵守其非商业使用限制及上游要求的版权声明。
- [NullArc](https://github.com/luuumi-dev/nullarc) 当前版本及许可状态请以上游 LICENSE、LICENSES/ 与 THIRD_PARTY_NOTICES.md 为准。
- [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone) 为上游项目，本仓库提供可选部署脚本入口；项目版权归上游所有。
- Apple 专有的 AppleHDA.kext 文件不在本仓库分发。
- 其他 Kext、UEFI 驱动和二进制文件均保留各自上游权利与许可证。再分发、修改或商业使用前，请逐项核对上游许可。

本项目按“现状”提供，不作任何明示或默示保证。使用 Hackintosh 可能涉及 Apple 软件许可条款限制，用户需自行确认适用的法律与许可要求。
