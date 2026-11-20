# 机械革命无界 14 Pro (Ryzen 7 7840HS / 780M) macOS 进系统测试实操指南

> **文档位置**：`mac端测试指南.md` (已同步至项目根目录与 EFI 分区)  
> **适用版本**：`v1.8_TEST_FIX_KEYBOARD_REMOVE_DISPLAY_OVERRIDE`  
> **更新时间**：2026-11-09

---

## 一、 快速救活 BetterDisplay 并开启 1920×1200 黄金视网膜分辨率

无界 14 Pro 物理屏幕为 **14 英寸 2880×1800 16:10**。系统原生只有 2880（字体微小如蚂蚁），必须开启 HiDPI 视网膜缩放。

### 1. 救活 BetterDisplay（解决“打不开 / 秒退 / 已损坏”问题）
打开 macOS 自带的 **终端 (Terminal)**，复制粘贴运行以下命令：

```bash
sudo xattr -cr /Applications/BetterDisplay.app
```
> **提示**：输入开机密码并回车（输入密码时屏幕不会显示星号，直接盲打回车即可）。

### 2. 双击打开并设置 1920×1200 HiDPI
1. 在“应用程序”中双击打开 **BetterDisplay**（屏幕右上角菜单栏会出现小显示器图标）。
2. 点击图标，选择你的内置显示器。
3. 勾选 **【开启原生平滑缩放 (Enable Smooth Scaling / HiDPI)】**。
4. 在分辨率滑块中，直接选中 **`1920 × 1200 (HiDPI)`**。
5. 屏幕会闪烁一下，立刻呈现出类似原生 MacBook Pro 般清晰、舒适、细腻的大字体！

---

### 3. 备选方案：一键 HiDPI 脚本（免常驻后台工具）
如果不想使用 BetterDisplay，可在终端中直接运行国内 Gitee 极速脚本激活系统设置里的 5 档原生缩放：

```bash
bash -c "$(curl -fsSL https://gitee.com/xzhih/one-key-hidpi/raw/master/hidpi.sh)"
```
1. 终端提示选择时输入 **`1`**（开启 HiDPI）。
2. 分辨率选择 16:10 推荐档位（如 `1920x1200` 等）。
3. 执行完毕后重启电脑，打开 `系统设置 ➔ 显示器`，即可直接点选苹果原生的 5 档缩放图块。

---

## 二、 无界 14 Pro 功能键盘快捷键实测清单

本版本（v1.8）已完整注入无界 14 Pro 专属键盘键码映射，请在进桌面后逐项测试：

| 按键位置 | 映射功能 | 预期 macOS 行为 | 测试结果 |
| :---: | :--- | :--- | :---: |
| **`F8`** | **静音开关** | 屏幕右上角弹出静音图标，喇叭静音/恢复声音 | [ ] |
| **`F9`** | **音量降低** | 屏幕弹出音量条，声音逐步降低 | [ ] |
| **`F10`** | **音量增加** | 屏幕弹出音量条，声音逐步增加 | [ ] |
| **`F11`** | **屏幕亮度降低** | 屏幕弹出系统原生太阳亮度条，画面变暗 | [ ] |
| **`F12`** | **屏幕亮度增加** | 屏幕弹出系统原生太阳亮度条，画面变亮 | [ ] |
| **`Win` 键** | **映射为 Command (⌘)** | 替代 Mac 专属按键：例如 `Win + C` 复制、`Win + V` 粘贴、`Win + 空格` 聚焦搜索 | [ ] |
| **`Alt` 键** | **映射为 Option (⌥)** | 作为 Mac Option 键使用 | [ ] |

---

## 三、 黑苹果避坑红线警示（为什么不能动 EFI 屏幕驱动）

> [!CAUTION]
> **绝对禁止向 EFI 中添加 `Display-Override.kext` 或任何声明 `AppleBacklightDisplay` 的伪装驱动！**
> 
> * **底层致命原因**：AMD Ryzen 7 7840HS + Radeon 780M 采用的是开源 NullArc 驱动接管 AMD DC（Display Controller）显示输出，底层根本没有苹果原厂的硬件背光控制器。
> * **严重后果**：强行向内核注入此类驱动，会导致苹果开机进度条走到一半（内核接管显示接口的瞬间）直接发生空指针崩溃，死锁卡死！
> * **规范法则**：分辨率与 HiDPI 调节纯属用户层行为，请一律使用 **BetterDisplay** 或 **one-key-hidpi** 在系统内完成，永不动 EFI 显卡内核驱动。

---

## 四、 极简回滚通道

如果 macOS 发生任何异常，随时返回 Windows：
1. 随时在桌面上运行 **`SYNC_EFI_TO_SSD.bat`**。
2. 历史版本完整存档在 `D:\EFI_Versions\`，可随时一秒刷回任何基线。


## USB-C 一线连外接显示器（本机已实机成功）

2026-11-20 回归确认：USB-C 一线连显示器（DP Alt Mode）可正常输出；Type-C 转 HDMI（QGeeM 扩展坞）也已由用户实机确认可用。DP 直连曾记录外屏 2560×1440@60Hz、内屏 2880×1800@120Hz 同时在线；HDMI 的精确分辨率/刷新率尚未记录。

- DP Alt Mode 两通道 HBR2，链路训练成功。
- 需要 NullArc PhxAccel 提供第二显示头 framebuffer；仅训练 DP 物理链路不够。
- 本机使用 `phxfb2=1` 启用第二 framebuffer，并由 `local.usbc-dp` LaunchDaemon 自动处理热插拔。
- 详细原理、实测寄存器、部署位置与限制见 [USB-C 一线连技术记录](USB-C-DP-BRINGUP.md)。

注意：当前只验证 2-lane HBR2 / 2560×1440@60Hz；尚未验证 4-lane DP、USB 3.x 并发、睡眠唤醒和其他扩展坞组合。

<!-- HW-OUTPUT-BT-K580-20261119 -->
## 五、AX200 蓝牙与 Logitech K580 回归（2026-11-19）

本机 Intel AX200 蓝牙 USB ID 为 8087:0029，系统 Tahoe 26.7.3（25G342）。本轮更新后实际加载版本：
- IntelBluetoothFirmware 2.5.2
- BTLEAdvFixup 0.9.3
- ForbiddenItlwm 0.6.0-beta.2
- BlueToolFixup 2.7.2

IntelBTPatcher 必须保持禁用；AirportItlwm 必须禁用，避免与 ForbiddenItlwm 同时工作。

检查命令：

    system_profiler SPBluetoothDataType
    kmutil showloaded | grep -E 'IntelBluetoothFirmware|BlueToolFixup|BTLEAdvFixup|ForbiddenItlwm|IntelBTPatcher'
    ioreg -l -w0 -d1 | grep 'BTLEAdv'

连接 BLE 键盘时，可观察 BTLEAdvEventPipes 与 BTLEAdvLengthRewrites 计数是否出现并变化。不要只凭蓝牙菜单可见就判定配对成功。

## 六、USB-C DP / HDMI 外接显示回归（2026-11-19）

- DP 直连基准：两通道 HBR2、外接 2560×1440 @ 60Hz、内屏 2880×1800 @ 120Hz。
- QGeeM Type-C 转 HDMI：已由用户确认实机输出正常；精确分辨率/刷新率、热插拔和睡眠唤醒仍待补测。
- 不把 DP 直连的分辨率数据直接套用到 HDMI 转接器。
- 不刷写或替换本机导出的 VBIOS。

完整记录见 USB-C-DP-BRINGUP.md 与 BLUETOOTH-K580-FIX.md。
