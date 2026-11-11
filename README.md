# Mechrevo Wujie 14 Pro — Ryzen 7 7840HS + Radeon 780M Hackintosh EFI

[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.8-blue.svg)](https://github.com/acidanthera/OpenCorePkg)
[![macOS Tested](https://img.shields.io/badge/Tested-macOS%20Tahoe%2026.6.2-success)](https://www.apple.com/macos/tahoe/)
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

<a name="english"></a>
# English

Hardware-specific OpenCore EFI configuration, troubleshooting notes, and macOS helper scripts for the **Mechrevo Wujie 14 Pro (机械革命 无界14 Pro)** featuring the **AMD Ryzen 7 7840HS (Zen 4 Phoenix)** processor and **AMD Radeon 780M (RDNA 3)** integrated graphics. **Tested on macOS Tahoe 26.6.2.**

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
| **Wi-Fi** | Intel Wi-Fi 6 AX200 (802.11ax) | :white_check_mark: AirportItlwm Native UI |
| **Bluetooth** | Intel AX200 Bluetooth 5.2 (`8087:0029`) | :white_check_mark: BlueToolFixup + Firmware |
| **Audio** | Senary (Conexant) CX8070 Codec (`14F1:1F87`) | :white_check_mark: Speaker & Headphone Out |
| **Microphone** | Internal AMD ACP digital microphone ([AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone)) | :white_check_mark: Works after macOS boots · [Deployment script](scripts/一键部署麦克风.command) |
| **Touchpad** | I2C HID Precision Multi-touch Touchpad | :white_check_mark: VoodooI2C Gestures |
| **Keyboard** | PS/2 Keyboard with Custom Fn Hotkeys (Volume, Brightness) | :white_check_mark: VoodooPS2 Remapped |
| **Battery** | Integrated Li-Polymer Battery (`F166003A`) | :white_check_mark: SMCBatteryManager |
| **Ports** | 2x USB 3.2 Gen 1 Type-A, 1x Full-featured Type-C, 1x USB4 Type-C, HDMI 2.1 | :white_check_mark: XhciNudge Zero-Lag |

---

## 2. Working Status & Features

- [x] **Radeon 780M Metal 3 Hardware Acceleration**: Enabled via [NullArc](https://github.com/luuumi-dev/nullarc) userland Mesa RADV driver stack and `PhxBringup.kext`. Buttery-smooth desktop rendering, Launchpad, and animations.
- [x] **120Hz Ultra-smooth Display**: Full support for native 2880x1800 @ 120Hz refresh rate.
- [x] **Zero USB Mouse/Keyboard Latency**: Integrated `XhciNudge.kext` and `xhcinudge=1` boot-arg eliminate the notorious AMD Zen 4 XHCI input stutter bug.
- [x] **Native Wi-Fi Control**: AirportItlwm provides native macOS menu bar Wi-Fi selection and high-speed wireless networking.
- [x] **Bluetooth Support**: Intel Bluetooth 5.2 pairs seamlessly with AirPods, mice, and keyboards via `IntelBluetoothFirmware` and `BlueToolFixup`.
- [x] **Multi-touch Gestures**: Fluid pinch-to-zoom, two-finger scrolling, and Mission Control swipes via `VoodooI2C` and `VoodooI2CHID`.
- [x] **Custom Keyboard Fn Shortcuts**: Volume mute/down/up (F8-F10), Brightness down/up (F11-F12), and swapped Win/Cmd keys.
- [x] **Battery Status & Power Management**: Accurate percentage readouts, charging cycle count, and dynamic CPU frequency scaling.
- [x] **Sleep & Wake**: Fast sleep and instant wake upon opening lid or pressing keys.
- [!] **Blind Login / Auto-login**: Due to [NullArc](https://github.com/luuumi-dev/nullarc) GPU pipeline architecture, the macOS `loginwindow` renders as a black screen until credentials are typed (or auto-login is enabled).

---

## 3. Included Scripts & Automation Utilities (`scripts/`)

To streamline post-installation and hardware optimization, several one-click macOS scripts are bundled in the [`scripts/`](scripts/) directory:

| Script Name | Purpose & Functionality | Usage |
| :--- | :--- | :--- |
| **`一键解决分辨率_开启HiDPI.command`** | **Screen Resolution & HiDPI Optimizer**<br>• Removes quarantine flags from BetterDisplay.<br>• Cleans corrupt WindowServer display cache.<br>• Enables 1920x1200 retina scaling via one-key-hidpi. | Double-click to run in Terminal |
| [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone) | [Deployment helper](scripts/一键部署麦克风.command) | [Upstream source](https://github.com/qhuyduong/AMDMicrophone) |
| [NullArc graphics installer](scripts/一键安装NullArc显卡驱动.command) | Radeon 780M Metal 3 installer; follows the upstream two-stage reboot process. | [NullArc upstream](https://github.com/luuumi-dev/nullarc) |
| [NullArc watchdog recovery script](scripts/NullArc显卡看门狗修复与复活.command) | Clears the GPU watchdog fallback state and helps recover 780M acceleration. | [NullArc upstream](https://github.com/luuumi-dev/nullarc) |

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
1. Create a bootable macOS Tahoe 26.6.2 installer USB flash drive.
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
4. On the next OpenCore picker, choose **Install macOS Tahoe 26.6.2**.

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
  - **[OpenIntelWireless](https://github.com/OpenIntelWireless)** (AirportItlwm & IntelBluetoothFirmware)
- **[AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone)** (AMD ACP 内置数字麦克风项目)

---
---

<a name="中文说明"></a>
# 中文说明

机械革命 **无界 14 Pro (MECHREVO WUJIE14 PRO)** 搭载 **AMD 锐龙 7 7840HS (Zen 4 Phoenix)** 处理器与 **AMD Radeon 780M (RDNA 3)** 核显的实机深度调优 OpenCore 黑苹果引导与全套辅助脚本项目。

本项目已在 **macOS Tahoe 26.6.2** 上完成实机测试；其他 macOS 版本尚未验证。

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
| **无线网卡** | Intel Wi-Fi 6 AX200 无线网卡 (802.11ax) | :white_check_mark: AirportItlwm 原生 Wi-Fi 选网 |
| **蓝牙模块** | Intel AX200 蓝牙 5.2 (`8087:0029`) | :white_check_mark: 蓝牙耳机与键鼠稳定配对 |
| **声卡芯片** | 新格 CX8070 声卡芯片 (`14F1:1F87`) | :white_check_mark: 扬声器外放与耳机输出正常 |
| **内置麦克风** | [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone) | :white_check_mark: 进入系统后通过[部署脚本](scripts/一键部署麦克风.command)加载正常 |
| **触控面板** | I2C HID 协议精密多点触控板 | :white_check_mark: VoodooI2C 原生多指手势丝滑跟手 |
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
3. **原生 Wi-Fi 图标与控制中心**：
   - 注入针对 Darwin 24/25 内核编译的 `AirportItlwm.kext`，状态栏右上角直接显示原生 Wi-Fi 扇形图标，支持一键切换无线网络。
4. **全套手势触控板体验**：
   - 采用 `VoodooGPIO` -> `VoodooI2CServices` -> `VoodooInput` -> `VoodooI2C` -> `VoodooI2CHID` 链式注入，支持单指轻点、双指缩放及三指调度。
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
1. 制作 macOS Tahoe 26.6.2 安装 U 盘。
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
  - **[OpenIntelWireless 团队](https://github.com/OpenIntelWireless)** (AirportItlwm 与 IntelBluetoothFirmware)
  - **AMD OS X 社区** (AMD Vanilla 内核补丁生态)
