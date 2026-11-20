# Mechrevo Wujie 14 Pro — Ryzen 7 7840HS + Radeon 780M Hackintosh EFI

> ## 🤖 AI Agent 一键部署提示词（中文）
>
> 你是本项目的 Hackintosh EFI 部署助手。优先从本仓库 GitHub Releases 获取最新正式版 EFI ZIP 和 SHA256SUMS。若仓库尚无正式 Release，则使用 main 分支的 `release/Mechrevo-Wujie14Pro-7840HS-780M-EFI.zip` 与 `release/SHA256SUMS.txt`，作为未打标签的候选包部署，并在结果中明确说明。
>
> 1. 先只读检查当前系统、磁盘、USB 设备；通过设备型号、容量、总线/连接方式识别目标 U 盘，不能仅凭盘符猜测。
> 2. 下载最新正式 Release 资产，校验 ZIP 完整性和 SHA-256；校验失败、Release 不存在或资产不完整时停止。
> 3. 若 U 盘已有 EFI 分区，先备份原 EFI 文件夹，再仅将压缩包内的 `EFI` 文件夹复制到该分区根目录，确保最终为 `EFI/BOOT` 和 `EFI/OC`。
> 4. 检查 `EFI/OC/config.plist` 可解析，`EFI/BOOT/BOOTx64.efi`、`EFI/OC/OpenCore.efi` 存在，并确认文件写入的是目标 U 盘。
> 5. 报告设备型号、容量、分区、备份位置、Release 版本、SHA-256 和部署结果；没有真实启动测试就不得声称启动成功。
>
> **安全红线：**绝不写入或格式化内置系统盘/数据盘。默认不格式化整个 U 盘，不删除已有 macOS 安装器或个人文件。若缺少 EFI 分区，先展示磁盘型号、容量、设备标识、分区方案和影响，等待我明确确认后才可分区/格式化。无法确认目标盘时立即停止。不得擅自修改 ACPI、config.plist、Kext 或启动参数。
>
> **重要：**本项目 EFI ZIP 只有引导文件，不包含完整 macOS 安装器。公开配置中的 Serial、MLB、UUID、ROM 是示例值，必须提醒我生成自己的 SMBIOS（机型身份信息），不得擅自编造或把示例值当成真实值。若当前环境无法可靠识别磁盘或执行文件操作，应如实说明并给出人工步骤，不得假装完成。
>
> 先检查并展示识别到的 U 盘，确认目标后再部署；每个破坏性操作都必须单独征求确认。
>
> ---
>
> ## 🤖 AI Agent One-Click Deployment Prompt (English)
>
> You are this project's Hackintosh EFI deployment assistant. Download the **latest stable GitHub Release** EFI ZIP and SHA256SUMS, then deploy the EFI to the USB drive I designate so I can test USB boot first.
>
> 1. Begin with read-only inspection of the OS, disks, and USB devices. Identify the target using its model, capacity, and connection/bus information; never guess from a drive letter alone.
> 2. Prefer the latest stable GitHub Release assets. If no stable Release exists yet, use `release/Mechrevo-Wujie14Pro-7840HS-780M-EFI.zip` and `release/SHA256SUMS.txt` from the repository main branch; label this as an untagged candidate package and disclose that it is not a formal Release.
> 3. If the USB already has an EFI partition, back up its existing EFI folder. Copy only the package's `EFI` folder to the root of that partition; the final layout must be `EFI/BOOT` and `EFI/OC`.
> 4. Verify that `EFI/OC/config.plist` parses, `EFI/BOOT/BOOTx64.efi` and `EFI/OC/OpenCore.efi` exist, and the files were written to the intended USB drive.
> 5. Report the device model, capacity, partition, backup location, Release version, SHA-256, and result. Never claim a successful boot unless it was actually tested.
>
> **Safety rules:** Never write to or format internal system/data disks. Do not format the whole USB by default or remove an existing macOS installer or personal files. If no EFI partition exists, show the disk model, capacity, device ID, proposed partition layout, and impact; wait for my explicit approval before partitioning or formatting. Stop if the target cannot be identified reliably. Do not modify ACPI, config.plist, Kexts, or boot arguments without approval.
>
> **Important:** This EFI ZIP contains boot files only, not a complete macOS installer. The public Serial, MLB, UUID, and ROM are placeholders; remind me to generate my own SMBIOS identity values. Never invent values or present placeholders as real. If the environment cannot reliably identify disks or perform file operations, say so and provide manual steps instead.
>
> Start by showing the USB drive identified through read-only inspection. Deploy only after the target is confirmed; obtain separate approval for every destructive operation.

---
[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.8-blue.svg)](https://github.com/acidanthera/OpenCorePkg)
[![macOS Tested](https://img.shields.io/badge/Tested-macOS%20Tahoe%2026.7.3-success)](https://www.apple.com/macos/tahoe/)
[![CPU](https://img.shields.io/badge/CPU-AMD%20Ryzen%207%207840HS-orange)](https://amd.com)
[![GPU](https://img.shields.io/badge/iGPU-Radeon%20780M%20(Metal%20Accelerated)-red)](https://github.com/luuumi-dev/nullarc)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](#english) | [中文说明](#中文说明)

> **发布包注意事项**
> - 本仓库面向机械革命无界 14 Pro / Ryzen 7 7840HS / Radeon 780M，属于特定硬件配置，不保证适用于其他机器。
> - 公开版 config.plist 中的 SMBIOS（机型身份信息）已替换为示例值。首次使用前必须自行生成并填写 Serial、MLB、UUID、ROM。
> - AppleHDA.kext 未随仓库分发；[NullArc](https://github.com/luuumi-dev/nullarc) 完整用户态驱动也需从上游单独获取。
> - 首次测试请使用 U 盘 EFI，提前备份能够启动的版本。


---


> **2026-11-20 实机更新**：当前 EFI 基于 macOS Tahoe 26.7.3（25G342 / Darwin 25.6.0）实机配置。USB-C 一线连显示器和 Type-C 转 HDMI 两种外接显示方式均已由用户实机确认可用；Intel AX200 的 AirDrop 也已在 26.7.3 上实测可用。公开 config.plist 已清空个人 SMBIOS 信息，首次使用必须自行生成。

## 2026-11-20 兼容性与稳定性提示

- **AirDrop（隔空投送）**：目前只有 macOS Tahoe 26.7.3 + 本仓库 AX200 驱动组合经过实机验证可用；其他 macOS 版本不作保证。若 AirDrop 是刚需，应优先选择 26.7.3。
- **NullArc 显卡稳定性**：26.7.3 下 Radeon 780M 虽可正常接管内屏，但目前观察到更容易触发 NullArc 降级保护。降级过程中可能伴随 WindowServer 重启、黑屏或当前图形登录会话退出；这不是 EFI 对所有机器的稳定性保证。
- **取舍建议**：需要 AirDrop 可选择 26.7.3，同时接受 NullArc 降级风险；更重视图形会话稳定性的用户，可等待后续 macOS / NullArc 更新或自行测试其他版本。后续 NullArc 上游升级及本项目改进可能改善这一情况。
- **外接显示**：USB-C 一线连（DP Alt Mode）与 Type-C 转 HDMI 均已在本机实测可用；具体 HDMI 分辨率/刷新率尚未记录。

## 2026-11-19 Test Records

- [2026-11-20 实机更新与兼容性说明](docs/发布说明-2026-11-20.md)

- [Physical verification](docs/实机验证记录-2026-11-19.md)
- [Touchpad diagnostic](docs/触控板诊断记录-2026-11-19.md)
- [SMBIOS setup](docs/SMBIOS配置指南.md)
- [GitHub release checklist](docs/发布前检查清单.md)
- [NullArc runtime scripts](scripts/nullarc-runtime/README.md)

<a name="english"></a>
# English

Hardware-specific OpenCore EFI configuration, troubleshooting notes, and macOS helper scripts for the **Mechrevo Wujie 14 Pro (机械革命 无界14 Pro)** featuring the **AMD Ryzen 7 7840HS (Zen 4 Phoenix)** processor and **AMD Radeon 780M (RDNA 3)** integrated graphics. **Tested on macOS Tahoe 26.7.3.**

---

## 1. Hardware Specifications

| Component | Hardware Model & Specifications | macOS Status |
| :--- | :--- | :---: |
| **Model** | Mechrevo Wujie 14 Pro (MECHREVO WUJIE14 Series-PHX) | :white_check_mark: Supported |
| **Processor** | AMD Ryzen 7 7840HS (8 Cores / 16 Threads, Zen 4, up to 5.1GHz) | :white_check_mark: Native Power Management |
| **Graphics** | AMD Radeon 780M (12 CUs, RDNA 3, PCI `1002:15BF`) | :white_check_mark: Metal Acceleration ([NullArc](https://github.com/luuumi-dev/nullarc)) |
| **Display** | 14.0" 2.8K (2880 × 1800), 16:10, 120Hz Refresh Rate, 100% sRGB | :white_check_mark: Native 120Hz & HiDPI |
| **Memory** | 16GB / 32GB Dual-Channel DDR5 5600MHz | :white_check_mark: Working |
| **Storage** | Dual M.2 PCIe 4.0 NVMe SSD slots | :white_check_mark: Native APFS |
| **Wi-Fi** | Intel Wi-Fi 6 AX200 (802.11ax) | :white_check_mark: ForbiddenItlwm 0.6.0-beta.2; AirDrop verified on macOS 26.7.3 only |
| **Bluetooth** | Intel AX200 Bluetooth 5.2 (`8087:0029`) | :white_check_mark: BlueToolFixup + Firmware |
| **Audio** | Senary (Conexant) CX8070 Codec (`14F1:1F87`) | :white_check_mark: Speaker & Headphone Out |
| **Microphone** | Internal AMD ACP digital microphone ([AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone)) | :white_check_mark: Works after macOS boots · [Deployment script](scripts/一键部署麦克风.command) |
| **Touchpad** | I2C HID Precision Multi-touch Touchpad | :warning: Driver stack loads; gestures need post-update verification |
| **Keyboard** | PS/2 Keyboard with Custom Fn Hotkeys (Volume, Brightness) | :white_check_mark: VoodooPS2 Remapped |
| **Battery** | Integrated Li-Polymer Battery (`F166003A`) | :white_check_mark: SMCBatteryManager |
| **Ports** | 2x USB 3.2 Gen 1 Type-A, 1x Full-featured Type-C, 1x USB4 Type-C, HDMI 2.1 | :white_check_mark: XhciNudge Zero-Lag |

---

## 2. Working Status & Features

- [x] **Radeon 780M Metal 3 Hardware Acceleration**: Enabled via [NullArc](https://github.com/luuumi-dev/nullarc) userland Mesa RADV driver stack and `PhxBringup.kext`. Buttery-smooth desktop rendering, Launchpad, and animations.
- [x] **120Hz Ultra-smooth Display**: Full support for native 2880x1800 @ 120Hz refresh rate.
- [x] **Zero USB Mouse/Keyboard Latency**: Integrated `XhciNudge.kext` and `xhcinudge=1` boot-arg eliminate the notorious AMD Zen 4 XHCI input stutter bug.
- [x] **Wi-Fi / AirDrop**: Intel AX200 uses ForbiddenItlwm 0.6.0-beta.2 with BTLEAdvFixup 0.9.3; AirDrop has been verified on macOS 26.7.3 only.
- [x] **Bluetooth Support**: Intel Bluetooth 5.2 pairs seamlessly with AirPods, mice, and keyboards via `IntelBluetoothFirmware` and `BlueToolFixup`.
- [!] **I2C Touchpad**: VoodooI2C / VoodooI2CHID load and match the device, but input-report delivery and multi-touch gestures must be re-confirmed on 26.7.3; see the touchpad diagnostic.
- [x] **Custom Keyboard Fn Shortcuts**: Volume mute/down/up (F8-F10), Brightness down/up (F11-F12), and swapped Win/Cmd keys.
- [x] **Battery Status & Power Management**: Accurate percentage readouts, charging cycle count, and dynamic CPU frequency scaling.
- [!] **Sleep & Wake**: Not verified on 26.7.3. A previous test reported kPMPCIUnsupported; do not assume system sleep works.
- [!] **Blind Login / Auto-login**: Due to [NullArc](https://github.com/luuumi-dev/nullarc) GPU pipeline architecture, the macOS `loginwindow` renders as a black screen until credentials are typed (or auto-login is enabled).

---

## 3. Included Scripts & Automation Utilities (`scripts/`)

To streamline post-installation and hardware optimization, several one-click macOS scripts are bundled in the [`scripts/`](scripts/) directory:

| Script Name | Purpose & Functionality | Usage |
| :--- | :--- | :--- |
| **`一键解决分辨率_开启HiDPI.command`** | **Screen Resolution & HiDPI Optimizer**<br>• Removes quarantine flags from BetterDisplay.<br>• Cleans corrupt WindowServer display cache.<br>• Enables 1920x1200 retina scaling via one-key-hidpi. | Double-click to run in Terminal |
| [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone) | [Deployment helper](scripts/一键部署麦克风.command) | [Upstream source](https://github.com/qhuyduong/AMDMicrophone) |
| [NullArc graphics installer](scripts/一键安装NullArc显卡驱动.command) | Radeon 780M Metal 3 installer; follows the upstream two-stage reboot process. | [NullArc upstream](https://github.com/luuumi-dev/nullarc) |
| [NullArc status checker](scripts/NullArc显卡看门狗修复与复活.command) | Read-only check for GPU, framebuffer and Xcode first-launch status; it does not reboot or clear logs. | [NullArc upstream](https://github.com/luuumi-dev/nullarc) |

---

## 4. BIOS Settings

Before booting OpenCore, configure the following settings in your BIOS (press **F2** on boot):

| Setting | Recommended Value | Reason |
| :--- | :--- | :--- |
| **Secure Boot** | **Disabled** | Required to load OpenCore bootloader |
| **Fast Boot** | **Disabled** | Allows EFI devices to be cleanly enumerated |
| **IOMMU** | **Disabled** (or Enabled) | Handled safely by OpenCore quirks |
| **UMA Framebuffer Size** | **Auto / 4G+** | Grants sufficient VRAM buffer for Radeon 780M |
| **Wake on LAN / USB** | **Disabled** | Prevents unexpected wakeups |

---

## 5. Quick Installation Guide

### Step 1: Prepare the USB Installer
1. Create a bootable macOS Tahoe 26.7.3 installer USB flash drive.
2. Mount the USB drive's EFI partition (`ESP`).
3. Download the latest release from the [`release/`](release/) directory (or clone this repository).
4. Copy the entire `EFI` folder (`BOOT` and `OC`) into the root of the USB drive's EFI partition.

### Step 2: Generate Unique SMBIOS Serials
To prevent Apple ID / iCloud / iMessage collisions, generate your own serial numbers using [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS):
1. Target model: **`MacBookPro16,1`**
2. Open `EFI/OC/config.plist` with ProperTree or OpenCore Configurator.
3. Replace the following keys under `PlatformInfo -> Generic`:
   - `SystemSerialNumber`
   - `MLB` (Board Serial)
   - `SystemUUID`
   - `ROM`

### Step 3: First Boot & Reset NVRAM (CRITICAL)
1. Insert the USB drive and press **F12** (or F7) at power-on to select the USB boot device.
2. In the OpenCore picker, press **Spacebar** to reveal auxiliary tools.
3. Highlight **`Reset NVRAM`** and press **Enter**. The system will restart automatically.
4. On the next OpenCore picker, choose **Install macOS Tahoe 26.7.3**.

### Step 4: Post-Installation, GPU Acceleration & HiDPI
1. Once installation completes and you reach the macOS desktop, enable **Automatic Login**:
   - Go to **System Settings** -> **Users & Groups** -> **Automatically log in as** -> select your user account.
2. Run [NullArc graphics installer](scripts/一键安装NullArc显卡驱动.command) to activate full Metal acceleration.
3. Run `scripts/一键解决分辨率_开启HiDPI.command` to set crisp 1920x1200 HiDPI resolution.

---

## 6. The Hall of Crash & Hangs (AMD Zen 4 Hackintosh Survival Guide)

This table summarizes the root causes and permanent fixes discovered during hard-fought debugging on this machine:

| Crash Case | Culprit / Trigger | Failure Symptom | Deep Technical Root Cause | Permanent Resolution |
| :---: | :--- | :--- | :--- | :--- |
| **#1** | **`IntelBTPatcher.kext`** | **Early Boot Panic Loop**: Kernel panic immediately upon boot; instant reboot back to OpenCore. | macOS 14+ removed private Bluetooth symbols. Kext hooking non-existent symbols triggers Kernel Trap 14. | **Permanently keep `IntelBTPatcher.kext` disabled!** Use only `IntelBluetoothFirmware` + `BlueToolFixup`. |
| **#2** | **AMD Zen 4 XHCI Controller** | **Severe Input Lag**: Mouse and keyboard take 2-3 seconds per packet; feels like a frozen system. | Native `AppleUSBXHCIPCI` lacks polling wakeup for Zen 4 XHCI, leading to queued burst reporting. | **Inject `XhciNudge.kext` and add `xhcinudge=1` to boot-args!** |
| **#3** | **`ProvideMaxSlide=100`** | **Prohibit Sign 🚫 in Phase 2**: `Err(0xE) <- EB.MM.AKMR` during secondary installer boot. | Enforcing MaxSlide 100 restricts memory search to 0-200MB. The 748MB installer DMG collided and aborted. | **Must set `ProvideMaxSlide=0`!** Unlocks all 256 slide slots. |
| **#4** | **`SecureBootModel=Default`** | **Prohibit Sign 🚫 in APFS Update**: `OPEN! Err(0xE) root_hash`. | Patched AMD kernel fails Apple Secure Boot T2 manifest root hash verification. | **Set `Misc -> Security -> SecureBootModel = Disabled`.** |
| **#5** | **[NullArc](https://github.com/luuumi-dev/nullarc) Blank Login Window** | **Black screen with working cursor** on boot. | [NullArc](https://github.com/luuumi-dev/nullarc) GPU rendering path cannot composite the native `loginwindow` UI. | **Type user password blindly and press Enter, or enable macOS Auto-Login.** |
| **#6** | **`Display-Override.kext`** | **System freeze halfway through Apple logo progress bar.** | Attaching `AppleBacklightDisplay` to AMD 780M Framebuffer dereferences null registers. | **Delete this kext completely!** Use BetterDisplay for HiDPI and scaling. |
| **#7** | **`MechrevoFan.kext`** | **Instant hardware power-off / reboot** upon kext injection. | Raw I/O port `0x66/0x68` concurrency conflicts with ACPI EC controller on Zen 4. | **Keep `MechrevoFan.kext` disabled** unless dedicated ACPI mutex patches are applied. |
| **#8** | **`phxboot.pending` NVRAM Lock** | **Endless reboot loop**: Rebooting every 90 seconds after `mesboot`. | Watchdog script writes state to NVRAM. Booting again without cleaning repeats watchdog. | **Press Spacebar in OpenCore and execute `Reset NVRAM`!** |

---

## 7. License & Credits

- Configured for the Mechrevo Wujie 14 Pro based on this machine’s hands-on testing. Compatibility may vary by BIOS and macOS build.
- Special thanks to:
  - **[Acidanthera](https://github.com/acidanthera)** (OpenCorePkg, Lilu, VirtualSMC, AppleALC, VoodooPS2)
  - **[NullArc / luuumi-dev](https://github.com/luuumi-dev/nullarc)** (AMD Radeon 780M Metal graphics driver)
  - **[VoodooI2C Team](https://github.com/VoodooI2C/VoodooI2C)** (Touchpad multitouch support)
  - **[OpenIntelWireless](https://github.com/OpenIntelWireless)** (IntelBluetoothFirmware)
- **[AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone)** (AMD ACP 内置数字麦克风项目)

---
---

<a name="中文说明"></a>
# 中文说明

机械革命 **无界 14 Pro (MECHREVO WUJIE14 PRO)** 搭载 **AMD 锐龙 7 7840HS (Zen 4 Phoenix)** 处理器与 **AMD Radeon 780M (RDNA 3)** 核显的实机深度调优 OpenCore 黑苹果引导与全套辅助脚本项目。

本项目已在 **macOS Tahoe 26.7.3** 上完成实机测试；其他 macOS 版本尚未验证。

---

## 一、硬件配置与驱动情况一览

| 硬件部件 | 规格与具体型号 | macOS 驱动状态 |
| :--- | :--- | :---: |
| **整机型号** | 机械革命 无界14 Pro (WUJIE14 Series-PHX) | :white_check_mark: 本机型专用配置 |
| **处理器** | AMD Ryzen 7 7840HS (8 核 16 线程, Zen 4 架构, 最高 5.1GHz) | :white_check_mark: 睿频调频与原生电源管理正常 |
| **集成核显** | AMD Radeon 780M (12 CUs, RDNA 3 架构, PCI `1002:15BF`) | :white_check_mark: [NullArc](https://github.com/luuumi-dev/nullarc) Metal 硬件加速生效 |
| **内建屏幕** | 14.0 英寸 2.8K 分辨率 (2880 × 1800), 16:10 比例, 120Hz 刷新率 | :white_check_mark: 原生 120Hz 高刷与 HiDPI 正常 |
| **内存容量** | 16GB / 32GB 双通道 DDR5 5600MHz | :white_check_mark: 正常识别使用 |
| **固态硬盘** | 双 M.2 PCIe 4.0 NVMe 插槽 | :white_check_mark: 原生 APFS 读写高速正常 |
| **无线网卡** | Intel Wi-Fi 6 AX200 无线网卡 (802.11ax) | :white_check_mark: ForbiddenItlwm 0.6.0-beta.2 + BTLEAdvFixup 0.9.3；26.7.3 隔空投送已实测可用 |
| **蓝牙模块** | Intel AX200 蓝牙 5.2 (`8087:0029`) | :white_check_mark: 蓝牙耳机与键鼠稳定配对 |
| **声卡芯片** | 新格 CX8070 声卡芯片 (`14F1:1F87`) | :white_check_mark: 扬声器外放与耳机输出正常 |
| **内置麦克风** | [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone) | :white_check_mark: 进入系统后通过[部署脚本](scripts/一键部署麦克风.command)加载正常 |
| **触控面板** | I2C HID 协议精密多点触控板 | :warning: 驱动已加载；输入报告和手势需在 26.7.3 上复测 |
| **笔记本键盘** | PS/2 键盘，深度重映射多媒体功能键 | :white_check_mark: F8-F10 调音量、F11-F12 调亮度 |
| **电池管理** | 原装锂聚合物电池 (`F166003A`) | :white_check_mark: SMCBatteryManager 准确显示百分比 |
| **扩展接口** | 2x USB 3.2 Gen 1, 1x 全功能 Type-C, 1x USB4 Type-C, HDMI 2.1 | :white_check_mark: XhciNudge 彻底根治输入延迟 |

---

## 二、功能特性与细节

1. **Radeon 780M 核显开启 Metal 3 硬件加速**：
   - 依赖 [NullArc](https://github.com/luuumi-dev/nullarc) 用户态 Mesa RADV 渲染栈与 `PhxBringup.kext` 内核桥接。
   - 访达窗口动画、程序坞磨砂、Launchpad 翻页及 120Hz 丝滑流畅。
2. **彻底解决 Zen 4 架构 USB 输入中断延迟**：
   - 注入专为 AMD 现代平台编译的 `XhciNudge.kext` 并配合启动参数 `xhcinudge=1`，周期性唤醒状态寄存器，彻底消除“鼠标几秒动一下”的严重卡顿！
3. **Intel AX200 无线网卡**：
   - 当前 EFI 启用 `ForbiddenItlwm.kext` 0.5.4；Wi-Fi 驱动已部署，AirDrop 需在 macOS 26.7.3 上重新验证。
4. **I2C 触控板驱动**：
   - 已按 `VoodooGPIO` -> `VoodooI2CServices` -> `VoodooInput` -> `VoodooI2C` -> `VoodooI2CHID` 顺序加载；26.7.3 下输入报告和多指手势尚待实机复测。
5. **定制键盘快捷键映射**：
   - F8 静音、F9 降音量、F10 增音量；F11 降亮度、F12 增亮度；自动互换 Win 与 Alt 键位（实现 Mac 标准 Cmd 与 Opt 布局）。

---

## 三、配套全自动运维脚本清单 (`scripts/`)

为降低黑苹果日常维护门槛，项目在 [`scripts/`](scripts/) 目录下贴心收录并重构了全套一键运维脚本：

| 脚本文件名 | 功能说明与适用场景 | 使用方式 |
| :--- | :--- | :--- |
| **`一键解决分辨率_开启HiDPI.command`** | **屏幕分辨率与 HiDPI 黄金缩放工具**<br>• 一键解除 BetterDisplay 秒退与隔离属性。<br>• 彻底清理 WindowServer 显示器脏缓存（解决改分辨率黑屏）。<br>• 内置 Gitee 极速 one-key-hidpi，开启 1920×1200 视网膜缩放。 | 双击直接在终端中运行 |
| [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone) | [一键部署麦克风脚本](scripts/一键部署麦克风.command) | [上游项目](https://github.com/qhuyduong/AMDMicrophone) |
| [NullArc 显卡驱动安装脚本](scripts/一键安装NullArc显卡驱动.command) | 780M Metal 3 驱动安装；按上游流程完成两阶段重启。 | [NullArc 上游项目](https://github.com/luuumi-dev/nullarc) |
| [NullArc 显卡看门狗恢复脚本](scripts/NullArc显卡看门狗修复与复活.command) | 清理显卡看门狗回退状态，辅助恢复 780M 硬件加速。 | [NullArc 上游项目](https://github.com/luuumi-dev/nullarc) |

---

## 四、BIOS 推荐设置项

开机狂按 **F2** 进入 BIOS 界面，检查并修改以下设置：

| 设置项 | 推荐设定值 | 说明 |
| :--- | :--- | :--- |
| **Secure Boot (安全启动)** | **Disabled (关闭)** | 必须关闭，否则无法载入第三方 OpenCore 引导 |
| **Fast Boot (快速启动)** | **Disabled (关闭)** | 确保开机完整枚举各总线硬件设备 |
| **IOMMU** | **Disabled 或 Enabled** | OpenCore 配置中已内置防死锁处理 |
| **UMA Frame Buffer Size** | **Auto 或 4G 以上** | 为 780M 核显分配充足的显存空间 |
| **网络唤醒 / USB 唤醒** | **Disabled (关闭)** | 避免合盖睡眠后异常唤醒发热 |

---

## 五、极速装机与部署指南

### 第一步：准备 U 盘并拷贝 EFI
1. 制作 macOS Tahoe 26.7.3 安装 U 盘。
2. 挂载 U 盘的 EFI 分区（ESP）。
3. 下载本项目 [`release/`](release/) 目录中的 `Mechrevo-Wujie14Pro-7840HS-780M-EFI.zip`。
4. 将解压出来的 `BOOT` 与 `OC` 两个文件夹完整拷贝到 U 盘的 `EFI/` 目录下。

### 第二步：生成专属三码（重要）
为防止多人使用相同序列号导致 Apple ID 异常或无法登录 iCloud/iMessage：
1. 下载 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 工具。
2. 选择型号：**`MacBookPro16,1`** 生成三码。
3. 打开 `EFI/OC/config.plist`，在 `PlatformInfo -> Generic` 下替换 `SystemSerialNumber`、`MLB`、`SystemUUID` 与 `ROM`。

### 第三步：首次开机必按空格【Reset NVRAM】
1. 插入 U 盘，开机按 **F12**（或 F7）选择 U 盘启动项。
2. 进入 OpenCore 图标选单后，**按下空格键**展开辅助工具。
3. 用方向键选中 **`Reset NVRAM`** 并回车，电脑会自动重启一次（彻底清除主板残留的错误地址缓存）。
4. 再次进入 OpenCore 选单，直接回车选中 **`Install macOS ...`** 开始安装。

### 第四步：进入系统后开启核显加速与 HiDPI 缩放
1. 进桌面后，先在【系统设置】->【用户与群组】中开启**【自动以此身份登录】**。
2. 运行 [NullArc 显卡安装脚本](scripts/一键安装NullArc显卡驱动.command) 部署 Mesa RADV 用户态加速环境，按提示重启两次。
3. 运行 `scripts/一键解决分辨率_开启HiDPI.command` 设定 1920×1200 黄金视网膜缩放。

---

## 六、避坑指南：AMD 锐龙黑苹果八大致命死因与根治方案 (The Hall of Crash & Hangs)

本项目在实机开发调试中，曾经历过无数次卡死、重启与禁止符，特将根因排查整理如下，供社区借鉴：

| 死亡案例编号 | 触发组件 / 操作 | 致命死因现象 | 底层技术机理剖析 | 终极解法 / 避坑准则 |
| :---: | :--- | :--- | :--- | :--- |
| **💀 死亡案例 1** | **`IntelBTPatcher.kext`**<br>(Intel AX200 蓝牙补丁) | **Early Boot Panic 死循环**：跑一堆代码后瞬间 Kernel Panic 黑屏并自动重启回到 OpenCore。 | macOS 14/15/26 彻底重构了蓝牙协议栈，移除了旧私有符号。驱动强行 Hook 不存在的内核符号触发内核内存陷阱 (Kernel Trap 14)。 | **【铁律】在现代 macOS 下永久禁用！**<br>保持 `IntelBTPatcher.kext -> Enabled: False`，仅保留 `IntelBluetoothFirmware` 与 `BlueToolFixup`。 |
| **💀 死亡案例 2** | **AMD Zen 4 XHCI 芯片**<br>(USB 中断延迟 Bug) | **几秒动一次超卡假死**：安装界面鼠标肉眼可见几秒才刷新一次，误以为是显卡没工作。 | 原生 `AppleUSBXHCIPCI` 缺少针对 AMD 控制器的状态轮询唤醒，USB 键盘鼠标数据包在队列中堆积 2~3 秒才批量上报。 | **注入 `XhciNudge.kext` 并添加 `xhcinudge=1` 启动参数！** 主动周期唤醒状态轮询。 |
| **💀 死亡案例 3** | **`ProvideMaxSlide=100`**<br>(内存检索上限约束) | **第二阶段安装报禁止标志 🚫**：报 `Err(0xE) <- EB.MM.AKMR`。 | 强制 OpenCore 仅在 0~200MB 物理内存内检索。第二阶段安装需 748MB 连续内存盘，硬塞碰撞导致内存分配失败中止。 | **必须设为 `ProvideMaxSlide=0`！** 开放全部 256 个 Slide 区间供检索。 |
| **💀 死亡案例 4** | **`SecureBootModel=Default`**<br>(Apple 安全引导) | **第二阶段更新报禁止标志 🚫**：报 `Err(0xE) usr\standalone\OS.dmg.root_hash`。 | AMD Vanilla 补丁修补了内核，触发 T2 芯片根哈希校验拦截。 | **必须将 `SecureBootModel` 改为 `Disabled`！** 彻底绕过原厂根哈希拦截。 |
| **💀 死亡案例 5** | **[NullArc](https://github.com/luuumi-dev/nullarc) 显卡盲打登录机理**<br>(登录界面全黑) | **开机进入登录界面全黑，仅有鼠标光标能活动**。 | [NullArc](https://github.com/luuumi-dev/nullarc) 官方明确说明，GPU 渲染管道无法合成渲染 macOS 原生的 `loginwindow` 窗口服务。 | **此时键盘盲打登录密码并按回车即可进入桌面，或在系统中开启“自动登录”！** |
| **💀 死亡案例 6** | **`Display-Override.kext`**<br>(屏幕伪装驱动) | **白苹果进度条过半死锁**：苹果进度条走到 1/3~1/2（显卡切换瞬间）画面永久冻结。 | 驱动强行挂载 `AppleBacklightDisplay` 到 AMD 780M Framebuffer，由于缺少硬件原生背光寄存器触发空指针崩溃。 | **【铁律】彻底移除该 kext！** 分辨率与缩放交由 BetterDisplay 管理。 |
| **💀 死亡案例 7** | **`MechrevoFan.kext`**<br>(机械革命风扇驱动) | **硬件看门狗瞬间重启**：驱动注入瞬间主板硬件级强行掉电重启。 | 驱动直接通过 I/O 端口 `0x66/0x68` 并发无锁读写嵌入式控制器（EC），在 Zen 4 下与 ACPI 产生严重硬件资源争用导致 EC 挂起。 | **禁止盲目开启！** 保持该条目为 `False`。 |
| **💀 死亡案例 8** | **NVRAM 遗留状态**<br>(`phxboot.pending` 挂起锁) | **连环重启“躺枪”**：明明改回了正确 EFI，开机依然自动重启。 | macOS 显卡守护进程异常退出时向主板 NVRAM 写入未完成标志，下次开机重复触发看门狗重启。 | **修改排错后必须按空格执行一次 `Reset NVRAM`！** 彻底清空主板异常状态位。 |

---

## 七、开源许可与致谢

- 本项目原创文档、辅助脚本与配置整理部分采用 MIT 开源许可证。第三方驱动与二进制组件遵循各自上游许可，详见 THIRD_PARTY_NOTICES.md。
- 诚挚感谢以下开源团队与先行者：
  - **[Acidanthera 团队](https://github.com/acidanthera)** (OpenCorePkg, Lilu, VirtualSMC, AppleALC, VoodooPS2)
  - **[NullArc / luuumi-dev](https://github.com/luuumi-dev/nullarc)**（AMD Radeon 780M Metal 显卡驱动体系）
  - **[VoodooI2C 团队](https://github.com/VoodooI2C/VoodooI2C)** (触控板多点触控支持)
  - **[OpenIntelWireless 团队](https://github.com/OpenIntelWireless)** (IntelBluetoothFirmware)
  - **[ForbiddenItlwm](https://github.com/retropineaple/ForbiddenItlwm)** (Intel AX200 Wi-Fi driver)
  - **AMD OS X 社区** (AMD Vanilla 内核补丁生态)

<!-- HW-OUTPUT-BT-K580-20261119 -->
## 2026-11-19 实机回归：USB-C 显示输出与 AX200 蓝牙

- USB-C DP Alt Mode：本机两通道 HBR2 已实测输出 2560×1440 @ 60Hz，内屏保持 2880×1800 @ 120Hz。
- USB-C 转 HDMI：QGeeM USB-C 多功能扩展坞在本轮更新后重启，用户确认 HDMI 输出恢复正常；本次未记录 HDMI 的具体分辨率/刷新率。
- AX200 / K580 蓝牙：蓝牙服务反复退出的问题经驱动组合更新与重启后恢复正常。当前组件为 IntelBluetoothFirmware 2.5.2、BTLEAdvFixup 0.9.3、ForbiddenItlwm 0.6.0-beta.2、BlueToolFixup 2.7.2。
- 配置要点：AirportItlwm 禁用，ForbiddenItlwm 与 BTLEAdvFixup 启用；IntelBTPatcher 保持禁用。

实测记录：[USB-C DP / HDMI](docs/USB-C-DP-BRINGUP.md) · [AX200 / K580 蓝牙修复](docs/BLUETOOTH-K580-FIX.md)
