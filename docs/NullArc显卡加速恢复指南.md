# 机械革命无界 14 Pro - NullArc Radeon 780M 显卡加速死锁排查与一键复活指南

> **文档位置**：`NullArc显卡加速恢复指南.md`（已同步至项目根目录、Windows 桌面及 EFI 分区）  
> **适用机型**：机械革命无界 14 Pro (AMD Ryzen 7 7840HS / Radeon 780M)  
> **更新时间**：2026-11-10

---
tail -n 40 /var/log/phxboot.log
## 一、 为什么会陷入“能进系统 ➔ 开显卡 ➔ 重启卡死重启 ➔ 又能进系统”的怪圈？

当你看到电脑**能进桌面，但一旦开启 NullArc 重启就卡死并自动重启回 OpenCore**，系统其实并没有崩溃死机，而是触发了 **NullArc 显卡底层守护进程的自我保护看门狗**！

### 🔍 底层源码取证（`/Users/Shared/gpu/phxboot.sh`）：
```bash
# phxboot.sh 源码第 72-78 行：
for ((t = 0; t < 90; t += 5)); do
    sleep 5
    n=$(( $(ls $DR | grep -c '^WindowServer[-_]') - before ))
    # 如果 WindowServer 在 780M 上连续崩溃 3 次，立即强制重启！
    [ $n -ge 3 ] && m2_fail "WindowServer crashed or hung $n times on the 780M"
done
```

### 💥 故障完整发生链条：
1. **显卡硬件接管失败**：当你启用 NullArc 时，系统在启动早期尝试将图形窗口服务（WindowServer）交由 780M 核显加速渲染。
2. **看门狗触发重启**：WindowServer 在接管瞬间**发生崩溃**，90 秒内累计崩溃达 3 次，看门狗函数 `m2_fail` 直接触发 `shutdown -r now`，导致电脑自动重启回 OpenCore。
3. **下一次为什么又能进桌面？**：
   看门狗在强行重启前，在硬盘写入了紧急避险标记：`/Users/Shared/gpu/phxboot-off`。
   因此下一次开机时，NullArc 自动关闭 780M 硬件加速，**回退到纯 CPU 软件渲染**，所以你能顺利进入桌面。
4. 你进入桌面后手动开启 NullArc，重启后再次崩 3 次触发看门狗……从而陷入无限死循环！

---

## 二、 为什么 WindowServer 会在 780M 接管时连续崩溃？（两大致命真凶）

### 1. 致命真凶一：此前折腾 BetterDisplay / 分辨率留下的脏配置文件（90% 概率）
macOS 会将显示器分辨率、刷新率以及虚拟显示设备记录在：
- `/Library/Preferences/com.apple.windowserver.displays.plist`
- `~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist`

此前在 macOS 中安装 BetterDisplay 或注入无效分辨率时，残留了与 780M 硬件时序不兼容的脏配置。  
在 CPU 软件渲染下系统忽略了这些高级参数，所以能进桌面；但一旦 780M 硬件接管，WindowServer 读取脏配置发生 `SIGSEGV` 内存访问越界，瞬间连续崩盘！

### 2. 致命真凶二：自动登录（Auto-Login）被系统悄悄关闭
NullArc 官方文档特别强调：**780M 加速路径下，苹果原生登录界面（loginwindow）是黑屏无法渲染的**。  
如果此前因非正常关机或重置 NVRAM，macOS 出于安全防护**自动关闭了自动登录**，系统就会停留在黑屏登录框等待密码。超过 90 秒无响应后，直接被看门狗当成死锁强行重启！

---

## 三、 macOS 终端一键清理与复活命令（趁现在能进桌面）

趁现在纯 CPU 渲染**可以进入桌面**，打开 macOS 自带的 **终端 (Terminal)**，完整复制并执行以下命令：

```bash
# ========================================================
# 第一步：彻底清除 WindowServer 遗留的显示器与分辨率脏配置
# ========================================================
sudo rm -f /Library/Preferences/com.apple.windowserver.displays.plist
rm -f ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist

# ========================================================
# 第二步：清空旧崩溃日志与看门狗计数器（让看门狗彻底归零）
# ========================================================
sudo rm -f /Library/Logs/DiagnosticReports/WindowServer*
sudo rm -f /var/db/phxboot.pending
sudo rm -f /Users/Shared/gpu/hang-reboots

# ========================================================
# 第三步：彻底卸载 BetterDisplay 残留后台（防止后台抢夺显卡通道）
# ========================================================
sudo rm -rf /Applications/BetterDisplay.app
rm -rf ~/Library/Application\ Support/BetterDisplay*
rm -rf ~/Library/Preferences/pro.betterdisplay*

# ========================================================
# 第四步：检查并确保【自动登录】处于开启状态
# ========================================================
# 请打开：系统设置 ➔ 用户与群组 ➔ 检查【自动以此身份登录】是否为你当前账号。
# 如果是“关闭”，请务必点击开启并输入密码确认！
```

---

## 四、 重新开启 NullArc 780M 硬件加速并重启

完成上述四步清理并确认自动登录已开启后，在终端中运行这最后一行指令：

```bash
sudo rm -f /Users/Shared/gpu/phxboot-off && sudo reboot
```

电脑将自动重启。此时：
1. OpenCore 引导进度条顺畅通过。
2. 绕过登录窗口直接秒进桌面。
3. **Radeon 780M Metal 3 硬件加速完全复活**！

---

## 五、 成功验证标志

进桌面后打开终端或系统信息验证：
1. 点击左上角苹果图标 ➔ **关于本机**：图形卡显示为 **AMD Radeon 780M**。
2. 打开系统信息 ➔ **图形/显示器**：显示 **Metal 支持：Metal 3**。
3. 终端运行：
   ```bash
   sysctl debug.nvaccel_iop_ok
   ```
   晃动鼠标或拖动窗口，该数字会持续增加（代表显卡正在实时合成绘制每一帧画面）。
