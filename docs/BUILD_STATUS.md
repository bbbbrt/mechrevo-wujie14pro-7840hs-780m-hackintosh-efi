# WUJIE14 Pro / Ryzen 7 7840HS — EFI 状态与迭代记录

> 公开说明：本文是开发过程的历史排错日志，不代表当前所有功能都已在所有系统版本完整验证。部分早期根因分析属于当时的诊断假设，应以实机日志和上游文档重新确认。个人密码及本机目录路径已清理。

## 目标环境
- 目标系统：macOS Tahoe 26.6.2（当前实测版本）
- 硬件架构：AMD Ryzen 7 7840HS (8 核 16 线程, Zen 4 Phoenix) / Radeon 780M (RDNA 3)
- 引导工具：OpenCore 1.0.8 DEBUG
- 镜像状态：**已成功进入 macOS 恢复界面（Recovery UI）**！

---

## 迭代与排错记录 (Iteration History)

### 轮次 1：卡在 `pci (build ...), flags 0xc0080` (Turn 1)
- **现象**：Verbose 滚动到 `ACPI: 31 ACPI AML tables successfully acquired and loaded`，打印 `pci (build ...), flags 0xc0080` 后死锁。
- **修复**：移除 `npci=0x3000`，禁用台式机热插拔补丁，保留 IVRS 表。

### 轮次 2：卡在 `pci (build ...), flags 0xc3080` (Turn 2)
- **现象**：去除 npci 后标志位恢复原生 `0xc3080`，但仍死锁在 `pci (build ...)` 前。
- **修复**：恢复 `DisableIoMapper=False` 消除对 IOPCIFamily 的损坏修补。

### 轮次 3：Kernel Trap 页错误 `Fault CR2: 0x00000000fff6f04c` (Turn 3)
- **现象**：内核在 0.51 秒崩溃报 Page Fault (Type 14)。
- **修复**：恢复 `DevirtualiseMmio=False` 与 `SetupVirtualMap=False`，主板 0xFF000000 闪存区映射恢复正常。

### 轮次 4：成功进入 Recovery UI；排查「几秒动一次」严重输入延迟根因与修复 (Turn 4)
- **现状进展**：机器已顺利通过所有早期内核引导阶段，完成 macOS 恢复环境的早期引导排错。
- **「鼠标几秒动一次、超卡超卡」的真相定位**：
  - 用户反馈外接鼠标“要几秒才动一次，像是显卡没干活”。
  - **深度技术真相**：这**不是**核显未加速导致的慢（纯 CPU 软解通常只是帧率较低但响应在毫秒级），而是 **AMD Zen 4 移动端 XHCI 芯片的严重 USB 输入中断延迟（USB Input Latency Bug）**！
  - 在 macOS 原生 `AppleUSBXHCIPCI` 下，AMD 移动平台的 USB 控制器缺少定期的状态寄存器刷新唤醒，导致 USB 鼠标与键盘的数据包被队列堆积，每隔 2~3 秒才批量上报一次，造成肉眼可见的“几秒动一次”假死感！
  - **解决方案**：引入针对现代 AMD 平台的专用驱动 [`XhciNudge.kext`]([本机路径已省略]) 并添加启动参数 `xhcinudge=1`，主动周期性激活 AMD XHCI 状态轮询，彻底清除数秒级的 USB 输入延迟！
- **自带键盘与触控板修复**：
  - 键盘与触控板驱动此前未加载或缺少 `VoodooInput.kext` 事件转发层。
  - 已按照严格依赖顺序激活全套驱动：`VoodooGPIO` ➔ `VoodooI2CServices` ➔ `VoodooInput` ➔ `VoodooI2C` ➔ `VoodooI2CHID` ➔ `VoodooPS2Controller` ➔ `VoodooPS2Keyboard`。
  - 在 `boot-args` 中添加 `-vi2c-force-polling` 参数（AMD I2C 轮询支持）。
- **核显（Radeon 780M）能否在恢复模式开启的解答**：
  - **结论：无法在恢复界面开启，必须装好系统后再开启。**
  - **技术原因**：[NullArc](https://github.com/luuumi-dev/nullarc) 显卡加速并非单纯的 kext 驱动，它依赖用户态的 Linux Mesa RADV 驱动堆栈（`/Users/Shared/gpu` 下的固件、`local.phxboot.plist` 守护进程以及 `/Library/Extensions` 的辅助内核包）。Recovery 界面是一个只读的精简内存镜像（BaseSystem.dmg），根本没有这套用户态运行环境。
  - 但一旦解决了上面的 USB 中断延迟与启用了原生 I2C 触控板，恢复模式操作将恢复正常可用，完全足以流畅完成磁盘格式化与系统安装！
- **网络方案确认**：
  - 极力推荐直接使用 **USB 3.0 转 RJ45 有线网卡**（免驱即插即用、满速下载且绝不丢包）。

### 轮次 5：输入完全恢复流畅；诊断 Type-C RJ45 恢复模式网络；部署并激活 Intel AX200 原生 Wi-Fi 驱动 (Turn 5)
- **输入状态用户确认**：
  - 用户实机反馈：“笔记本的触摸板和键盘都可以了，usb鼠标也不卡顿了”！
  - 键盘、触控板、USB 鼠标全部恢复即时跟手响应！
- **恢复模式终端网络排查与诊断指南**：
  - **唤起终端**：恢复界面顶部菜单栏点击 **【实用工具】(Utilities)** ➔ **【终端】(Terminal)**。
  - **检查网卡接口**：输入 `ifconfig`，观察是否有网络设备（`en0`、`en1` 等）处于 `status: active` 状态，并查看是否分配到局域网 IP (`inet 192.168.x.x`)。
  - **强制申请 IP**：如果接上网线显示 `active` 但无 IP，执行 `ipconfig set en0 DHCP`（或针对 `en1`）。
  - **连通性测试**：执行 `ping -c 3 223.5.5.5`，若能正常接收回复包则外网通畅。
  - **Type-C 接口切换**：无界 14 Pro 左侧有两个 Type-C 接口（一个全功能 USB 3.2 Gen 2，一个 USB4），不同芯片协议支持略有差异，若未识别可热插拔至相邻的另一个 Type-C 端口。
- **Intel AX200 原生 Wi-Fi 全面激活**：
  - 获取并替换为专门针对 **当时尝试使用的 macOS 安装介质版本** 编译的最新发布版 [`AirportItlwm.kext`]([本机路径已省略])（v2.4.0-alpha-7204c69，二进制 15.9 MB）。
  - `config.plist` 将 `AirportItlwm.kext` 设置为 `Enabled = true`，匹配内核区间 `MinKernel: 24.0.0` 至 `MaxKernel: 24.99.99`。
  - 重新引导后进入恢复模式，屏幕**右上角**将直接显示原生 Wi-Fi 图标，可直接连接无线局域网。
- **当前验证与部署状态**：
  - 本地 EFI 与 U 盘 `[本机路径已省略] 均已更新完毕并通过 `ocvalidate`（0 错误）。
  - 恢复模式下磁盘准备：打开【磁盘工具】 ➔ “显示所有设备” ➔ 抹掉安装盘为 `APFS` / `GUID 分区图` ➔ 启动【重新安装 macOS】在线下载安装。

### 轮次 6：第二阶段安装引导排查；定位「禁止标志 ⊘ (support.apple.com/mac/startup)」根因与修复 (Turn 6)
- **现象复现与用户反馈**：
  - 用户在恢复模式下成功将 macOS 安装第一阶段文件写入本地磁盘 `mac`，机器自动重启进入 OpenCore 选单。
  - 选单新增第二阶段条目 `3. macOS Installer`。
  - 用户选中 `macOS Installer` 后，屏幕未打印 Verbose 文本，而是直接显示苹果「禁止标志 ⊘」及网址 `support.apple.com/mac/startup`。
- **深度日志根因分析 (抓取自实机 `[本机路径已省略]
  ```
  152:215 00:068 AAPL: #[EB|SB:SBGMFNS] j152fap.im4m
  152:284 00:068 AAPL: #[EB|RH:PF] usr\standalone\OS.dmg.root_hash
  152:353 00:069 AAPL: #[EB|RH:MF] <"usr\\standalone\\OS.dmg.root_hash.j152fap.im4m">
  152:442 00:088 AAPL: #[EB.LD.LF|IN] 0 1 <"usr\\standalone\\OS.dmg.root_hash"> <"0">
  152:521 00:079 AAPL: #[EB.LD.OFS|OPEN!] Err(0xE) <"usr\\standalone\\OS.dmg.root_hash">
  152:590 00:068 AAPL: #[EB.RH.LRH|P!] Err(0xE) <- EB.LD.LF
  152:659 00:068 AAPL: #[EB.BST.FBS|!] Err(0xE) <- EB.RH.LRH
  ```
  - **技术定性**：Apple 安全引导（Apple Secure Boot）在引导本地第二阶段 APFS 更新宗卷时触发校验拦截！
  - **为何第一阶段 Recovery 能进？** Recovery 是官方打包的 `BaseSystem.dmg` 纯原镜像，带有苹果原厂根签名。
  - **为何第二阶段报错禁止符？** 本地 APFS 分区生成的内核与引导环境已被 `AMD_Vanilla` 内核补丁修补（绕过 Intel CPU 限制），导致哈希与 T2 芯片清单（`j152fap.im4m`）不符。当 `SecureBootModel` 被设置为 `Default` 时，`boot.efi` 强制执行根哈希校验（Root Hash），找不到对应哈希文件报 `Err(0xE)`，直接挂起并呈现禁止标志！
  - 此外，`HideVerbose` 设为 `true` 导致此拦截过程静默黑屏，未能在屏幕上直接显示引导中断细节。
- **修复方案与落实**：
  1. **关闭 Apple 安全引导校验**：将 `Misc ➔ Security ➔ SecureBootModel` 从 `Default` 改为 **`Disabled`**（黑苹果跨阶段安装的标准强制项）。
  2. **开放详细输出**：将 `UEFI ➔ APFS ➔ HideVerbose` 改为 **`false`**，避免第二阶段静默黑屏。
  3. **跳过兼容性型号限制**：在 `boot-args` 中追加 **`-no_compat_check`**。
- **生效状态**：
  - 配置通过 `ocvalidate` 校验（0 错误）。
  - 已全量写入 U 盘 `[本机路径已省略]

### 轮次 7：二次禁止标志 ⊘ 排查；分析 U 盘日志定位 KASLR 内存分配失败 (Turn 7)
- **现象复现与用户反馈**：
  - 用户反馈上一版本修改后重新引导 `macOS Installer` 依然出现禁止标志 `🚫`。
- **深度日志根因分析 (抓取自实机 `[本机路径已省略]
  ```text
  522:66:063 00:042 OCSB: Secure boot is disabled, skipping
  530:66:460 00:074 OCABC: No slide values are usable! Falling back to 80 with 0x2A27F000 bytes!
  ...
  175:288 00:040 AAPL: #[EB|MBA:KF] <"-no_panic_dialog -rootdmg-ramdisk auth-root-dmg=file:///macOS%20Install%20Data/BaseSystem.dmg lca-boot-mode=autoinstall-msu">
  175:339 00:050 AAPL: #[EB|MBA:OUT] <... slide=80  -no_panic_dialog -rootdmg-ramdisk ...>
  175:576 00:076 AAPL: #[EB.MM.AKMR|!] Err(0xE) <- EB.M.BAPr2 2 2 191520 0xa100000
  175:657 00:040 AAPL: #[EB.B.MN|!] Err(0xE) <- EB.MM.AKMR
  179:110 00:040 AAPL: #[EB|STOP] 0x15
  179:239 00:048 AAPL: Displaying boot failure graphic for 10 seconds...
  189:459 00:043 OC: Boot failed - Aborted
  ```
- **核心技术机理剖析**：
  1. **安全引导已被成功跳过**：`OCSB: Secure boot is disabled, skipping`，证明 Turn 6 的 `SecureBootModel=Disabled` 已经生效。
  2. **第二阶段大内存盘加载**：安装第二阶段需挂载 `macOS Install Data/BaseSystem.dmg` 内存盘（191520 页 = 748.1 MB）。
  3. **ProvideMaxSlide 限制引发连锁崩溃**：
     - 此前 `config.plist` 的 `Booter -> Quirks -> ProvideMaxSlide` 值为 `100`。
     - 该参数强制 OpenCore 只在 Slide 0~100 区间检索连续可用内存（对应物理内存低地址 0~200MB 范围）。
     - 748MB 的巨量连续内存根本无法塞入 200MB 以内，导致 OpenCore 触发回退机制：`FallbackSlide = MaxSlide - 20 = 80`。
     - OpenCore 向 NVRAM 强行注入 `slide=80`。
     - `boot.efi` 根据 `slide=80` 计算起始物理地址为 `0x100000 + 80 * 0x200000 = 0x0A100000`，并执行 `AllocatePages(AllocateAddress, 191520, 0xa100000)`。
     - 该硬编码低地址与 UEFI 固件保留区冲突或不足连续 748MB，UEFI 固件返回 `Err(0xE)`（`EFI_NOT_FOUND` / `EFI_OUT_OF_RESOURCES`）。
     - `boot.efi` 因无法为内核与内存盘分配内存（`AllocateKernelMemoryRange`）直接中止，触发禁止符 🚫。
- **修复措施与技术验证**：
  1. **解除 Slide 检索上限**：将 `Booter -> Quirks -> ProvideMaxSlide` 从 `100` 改为 **`0`**（默认安全模式，完全开放 0~255 全量 256 个 Slide 区间供检索）。根据实机内存映射计算，主内存描述符 #7（`0x09F3C000` ~ `0x42358000`，共 943.8MB 连续可用内存）可提供从 Slide 80 到 191 共 112 个合法可用区间，彻底避免回退碰撞。
  2. **全盘同步更新**：同步写入本地两份 EFI（`EFI/OC/`、`EFI-MINIMAL/`）、U 盘当前引导 `[本机路径已省略] U 盘核心备份包 `[本机路径已省略]
  3. **工具验证**：经 `ocvalidate.exe` 校验，全部 0 错误通过。
- **用户操作要点**：
  - 启动进入 OpenCore 菜单时，**必须先按空格键（或方向键）选中 `5. Reset NVRAM` 回车一次**，彻底清除此前驻留在 NVRAM `boot-args` 中的残留参数 `slide=80`。
  - 机器自动重启再次进入 OpenCore 选单后，回车选择 **`3. macOS Installer`** 即可顺利进入第二阶段安装流程。

---

### 轮次 8：macOS Tahoe 26.6.2 镜像恢复与进系统黑屏仅有鼠标排查（[NullArc](https://github.com/luuumi-dev/nullarc) / Radeon 780M 驱动与盲打登录机理） (Turn 8)
- **现状与用户反馈**：
  - 用户通过 R-Drive Image（镜像密码已省略。
  - 用户通过 U 盘 OpenCore 引导进入恢复后的 macOS Tahoe 26.6.2，内核顺利引导，鼠标指针活动自如，但屏幕全黑无图形界面（“只有鼠标可以活动，什么都看不到，黑色的，应该是把 780m 的驱动加载了但是还是黑色”）。
- **技术根因深度定位**：
  1. **本地 EFI 未开启 780M 硬件桥接与 AMFI 旁路**：
     - 本地 `config.plist` 此前将 `PhxBringup.kext` 与 `AMFIPass.kext` 均设为 `Enabled: false`。
     - `boot-args` 缺少 [NullArc](https://github.com/luuumi-dev/nullarc) 必需的启动参数：`amfi=0x80 amfi_get_out_of_my_way=0x1 -amfipassbeta ipc_control_port_options=0 phxdebug=1`。
     - 在 macOS Tahoe（Darwin 25）中，系统去除了 CPU 软解 Quartz 渲染器，WindowServer 在缺少 Metal 显卡驱动或签名校验拦截时无法合成桌面窗口，导致画布为全黑，仅顶层硬件光标图层正常跟踪鼠标。
  2. **[NullArc](https://github.com/luuumi-dev/nullarc) 官方文档记载的已知特性（登录窗口全黑）**：
     - [NullArc](https://github.com/luuumi-dev/nullarc) 官方开发文档 `INSTALL.md` 明确说明：
       > *"With --windowserver, turn on automatic login... the login window may come up black on the GPU path."*
     - 当镜像中部署了 [NullArc](https://github.com/luuumi-dev/nullarc) GPU 驱动及 `--windowserver` 守护进程后，macOS 的原生登录界面（`loginwindow`）在 GPU 合成路径上**无法渲染出 UI 元素，呈现完全黑屏**！
      - 此时系统并非卡死，而是在静默等待登录。输入你自己的 macOS 登录密码并回车，即可继续进入桌面。
- **配置修复与验证**：
  1. **启用 Radeon 780M 驱动**：`PhxBringup.kext` ➔ `Enabled: true`（MinKernel: `25.0.0`）。
  2. **启用 AMFI 签名旁路**：`AMFIPass.kext` ➔ `Enabled: true`。
  3. **更新完整启动参数**：
     `-v -dbgenhiolog -dbgenhdbg keepsyms=1 debug=0x100 revpatch=cpuname,sbvmm alcid=15 -vi2c-force-polling xhcinudge=1 -no_compat_check ipc_control_port_options=0 -amfipassbeta amfi=0x80 amfi_get_out_of_my_way=0x1 phxdebug=1`
  4. **配置校验**：经 `ocvalidate.exe` 校验，0 错误通过。
  5. **一键同步工具**：创建 `[本机路径已省略] Windows 下 ESP 系统分区由于 ACL 保护无法在非管理员状态直接写入的问题，双击即可请求提权并自动将最新修复同步到 U 盘 `[本机路径已省略]

---

### 轮次 12：macOS Tahoe 26.6.2 声音与麦克风驱动框架补全 (Turn 12)
- **现象定位**：进入系统后音频与麦克风无设备识别；macOS Tahoe 26.6.2 原生彻底移除了 `AppleHDA.kext` 和 `IOHDAFamily.kext`，导致 `AppleALC.kext` 无底层 HDA 总线挂载。此外，无界 14 Pro 声卡芯片实际报码为 Senary CX8070 (`0x14F11F87`)，而公版 AppleALC 仅收录了 `0x14F11F86`。
- **修复方案与落实**：
  1. 引入专为 Darwin 25/26 编译的完整 `AppleHDA.kext` 驱动套件（含 `IOHDAFamily`、`AppleHDAController`、`DspFuncLib`、`AppleHDAHardwareConfigDriver`）。
  2. 严格按依赖树顺序将驱动注入 `config.plist` 的 `Kernel ➔ Add`（置于 `AppleALC.kext` 之前）。
  3. 为 `AppleALC.kext` 的 `Info.plist` 增补 `0x14F11F87` (351346567) 芯片 ID 映射，完美继承 layout-id 15 与 21 的引脚与唤醒定义。
  4. 备份原稳定配置为 `config.plist.working-gpu-120hz.bak`。

---

### 轮次 13：IntelBTPatcher 致命死循环标记与 CX8070 内置麦克风 Node 0x1A 尝试 (Turn 13)
- **现象与排查**：
  - 用户进入 macOS 调试期间，尝试通过注入 `VoodooHDA_BL.kext` 解决声音问题，并在其 `Info.plist` 的 `NodesToPatch` 中尝试配置 `Node 26 (0x1A)`。
  - 在配置保存过程中，`IntelBTPatcher.kext` 被配置编辑器重新勾选为 `True`。
  - 重启后机器发生 **Early Boot Panic**，直接呈现“跑一堆条后卡死并瞬间重启回到 OpenCore”的无休止死循环。
- **致命根因诊断**：
  - 苹果在现代 macOS（Sonoma 14+ / Tahoe 26+）中重构了蓝牙协议栈，彻底移除并重排了私有符号表。`IntelBTPatcher.kext` 强行 Hook 私有符号直接触发内核内存陷阱（Kernel Trap 14）。

---

### 轮次 14：建立严格的单变量物理版本库体系与一键固化/提取工具 (Turn 14)
- **管理规范确立（维护铁律）**：
  1. **单变量排错原则**：每次只改动一项组件或参数，严禁多项并发修改导致因果关系混乱。
  2. **物理独立文件夹双轨制**：在 `[本机路径已省略] 建立版本快照文件夹，在 `[本机路径已省略] 内嵌 Git 历史仓库。
  3. **用户专属归档确认权**：只有用户本人明确下达指令并确认 100% 稳定的版本才可归档（Stable Archive），测试版本绝不擅自越级。
- **版本链条梳理**：
  - `v1.0_STABLE_ARCHIVE_26.6.2`：基线稳定版（核显、Wi-Fi 正常，无声卡电池）。
  - `v1.1_TEST_HANG_BEFORE_FIX`：初次添加背光/蓝牙/电池后卡死版本。
  - `v1.2_TEST_REMOVE_PNLF`：单变量仅去掉 PNLF，实测仍卡死。
  - `v1.3_TEST_RESTORE_PNLF_DISABLE_BTPATCHER`：**关键突破**！恢复 PNLF，仅禁用 `IntelBTPatcher.kext`，实机成功开机！
  - `v1.5_TEST_ONLY_DISABLE_INTELBTPATCHER`：**实测成功**！100% 继承固态最新配置，仅关闭 `IntelBTPatcher.kext`，用户实测“刚才确实好了”，成功进入桌面！

---

### 轮次 15：实机照片深度研判（mesboot / Wi-Fi 心跳）与 NVRAM 挂起锁解除 (Turn 15)
- **用户实机抓拍现场分析**：
  - 屏幕显示：`map_with_linking_np: [479(mesboot)]: region 0, not code signed`，随后伴随 Wi-Fi 信号轮询 `LQM-WiFi...` 重复刷新，等待约 90 秒后黑屏自动重启。
  - **关键真相 1：引导已完全成功进用户态！**  
    PID 479 为 [NullArc](https://github.com/luuumi-dev/nullarc) 核显加速辅助工具 `/Users/Shared/gpu/phxctl/mesboot`。“region 0, not code signed”仅为开源二进制无签名常规告警，证明 OpenCore 和 Kernel 驱动阶段已经 100% 通过！
  - **关键真相 2：重启是由 phxboot.sh 看门狗触发！**  
    因音频总线冲突或窗口服务超时，用户态显卡引导脚本 `phxboot.sh` 检测到 `WindowServer` 未能正常渲染，脚本主动触发了内建的 `shutdown -r now` 保护指令。
  - **关键真相 3：NVRAM 遗留挂起锁导致开机“连环重启”！**  
    看门狗脚本触发后，会在主板 NVRAM 中写入状态标志（`phxboot.pending`）。若开机未重置 NVRAM，下次启动脚本会认为上次未完成，再次触发重启！
- **修复与恢复方案**：
  1. `[本机路径已省略] 工作目录 100% 完整无损还原至实测通的 `v1.5_TEST_ONLY_DISABLE_INTELBTPATCHER`。
  2. 开机时在 OpenCore 选单中按空格键执行 **`Reset NVRAM`**，彻底解除主板异常锁。

---

### 轮次 16：极速静音引导上线与开机日志关闭 (v1.7_TEST_FAST_BOOT_NO_DEBUG)
- **技术诉求与背景**：
  - 用户反馈 OpenCore 引导及 macOS 启动速度较慢。
  - 此前 OpenCore 启用了 DEBUG 模式，每开机一次都在 FAT32 分区写入上万条微小日志（`opencore-*.txt`），严重阻塞 EFI 分区写入速度；同时开启了 `DebugEnhancer.kext` 和 `-v` 跑代码。
  - 用户已在 macOS 中**成功开启了系统自动登录（Auto-Login）**，彻底绕过了 Radeon 780M 无法合成渲染的原生 `loginwindow` 登录框盲打密码问题。
- **调优动作**：
  1. `NVRAM ➔ boot-args`：剔除 `-v`（彻底关闭滚屏跑码，直出干净白苹果进度条）、剔除 `-dbgenhiolog`、`-dbgenhdbg`。保留关键硬件驱动与核显参数。
  2. `Misc ➔ Debug`：`Target = 0`（完全停用 OpenCore 落盘写日志），`AppleDebug = False`，`LogModules = ""`。
  3. `Misc ➔ Boot`：`Timeout = 2` 秒。
  4. `Kernel ➔ Add`：`DebugEnhancer.kext` 设为 `False`。
  5. 固态硬盘与物理版本库：已生成 `[本机路径已省略] Git 提交固化。

---

### 轮次 17：屏幕伪装驱动冲突排查与功能键规范化 (v1.8_TEST_FIX_KEYBOARD_REMOVE_DISPLAY_OVERRIDE)
- **技术排查背景**：
  - 用户从 macOS 尝试新增“分辨率选择”与“无界 14 Pro 功能键盘按键”，导致开机苹果进度条走到一部分瞬间卡死。
  - 从固态硬盘现场提取（`PULL_EFI_FROM_SSD.bat`）分析，锁定两大改动：
    1. 新增 `Display-Override.kext` 并伪装 `com.apple.driver.AppleBacklightDisplay`。
    2. 修改 `VoodooPS2Keyboard.kext` 注入 F8~F12 快捷键与 Win/Alt 交换，但包含非 ASCII 字符注释。
- **真凶定性**：
  - `Display-Override.kext` 强行将 `AppleBacklightDisplay` 挂载到 AMD 780M Framebuffer（由 [NullArc](https://github.com/luuumi-dev/nullarc) `PhxBringup.kext` 管理）上，由于缺少苹果原生背光硬件寄存器，在显示流水线初始化（进度条过半）瞬间触发空指针/死锁崩溃。
- **治理与修复方案**：
  1. **彻底剔除 `Display-Override.kext`**（分辨率切换应交由用户层工具如 BetterDisplay，禁止在内核层做伪装注入）。
  2. **规范化 `VoodooPS2Keyboard` 映射表**：保留 F8 静音(`42=4a`)、F9 降音量(`43=49`)、F10 增音量(`44=48`)、F11 降亮度(`57=90`)、F12 增亮度(`58=91`)，以及 `Swap command and option`（Win=Cmd, Alt=Opt），剔除可能引发解析隐患的非 ASCII 字符。
  3. 版本固化为 `[本机路径已省略] `ocvalidate` 核验（0 Error）。

---

### 轮次 18：AMDMicrophone 内置数字麦克风部署方式
- 本机尝试在 OpenCore 启动阶段加载麦克风驱动时发生启动卡死。
- 当前公开方案改为在 macOS 桌面启动后，使用[部署辅助脚本](../scripts/一键部署麦克风.command)；驱动来源与具体要求以 [AMDMicrophone 上游项目](https://github.com/qhuyduong/AMDMicrophone) 为准。
- 此记录仅描述本机测试结果，不代表所有 AMD ACP 设备均兼容。
---

## ☠️ 死亡记录与黑苹果血泪避坑档案 (The Hall of Crash & Hangs)

本项目在 AMD Ryzen 7 7840HS (Zen 4 Phoenix) / Radeon 780M 适配过程中，踩过的所有**致命崩溃（死循环、卡死、黑屏）**技术归档：

| 死亡案例编号 | 触发组件 / 操作 | 致命死因现象 | 底层技术机理剖析 | 终极解法 / 避坑准则 |
| :---: | :--- | :--- | :--- | :--- |
| **💀 死亡案例 1** | **`IntelBTPatcher.kext`**<br>(Intel AX200 蓝牙补丁) | **Early Boot Panic 死循环**：跑一堆 Verbose 条码后瞬间 Kernel Panic 并黑屏自动重启回到 OpenCore。 | macOS 14/15/26 彻底重构了蓝牙协议栈，移除了旧私有符号。驱动强行 Hook 不存在的内核符号触发内核内存陷阱 (Kernel Trap 14)。 | **【铁律】在现代 macOS 下永久禁用！**<br>保持 `IntelBTPatcher.kext ➔ Enabled: False`，仅保留 `IntelBluetoothFirmware` 与 `BlueToolFixup`。 |
| **💀 死亡案例 2** | **`MechrevoFan.kext`**<br>(机械革命风扇控制) | **硬件看门狗瞬间重启**：驱动注入瞬间主板硬件级强行掉电重启。 | 驱动直接通过 I/O 端口 `0x66/0x68` 并发无锁读写嵌入式控制器（EC）。在 AMD Zen 4 架构下，与 ACPI 产生严重硬件资源争用，导致 EC 控制器挂起死锁。 | **禁止裸读写 EC 端口！**<br>在无专用 AMD ACPI 互斥锁补丁前，保持该 kext 为 `False`。 |
| **💀 死亡案例 3** | **`VoodooHDA_BL.kext`**<br>(错配 Codec 0 注入 Node 26) | **音频总线死锁与看门狗重启**：进入用户态后，屏幕定格在 `mesboot` 与 `LQM-WiFi`，90 秒后重启。 | 将内置麦克风 Node 26 强行绑在 `Codec 0` 上。但在 7840HS 上，`Codec 0` 是 780M HDMI/DP 数字音频，无此模拟引脚。CoreAudio 启动时向 HDMI 下发模拟麦克风配置，导致音频总线发生 CORB/RIRB 超时死锁。 | **禁止在 Codec 0 注入模拟音频节点！**<br>移除非法 NodesToPatch 节点，保持干净基线。 |
| **💀 死亡案例 4** | **`SSDT-PNLF.aml`**<br>(公版屏幕背光补丁) | **低端内存踩踏卡死**：卡在 `pci (build ...), flags 0xc0080` 阶段无法推进。 | 公版 SSDT-PNLF 包含错误的 `_UID 0x0E` 或与主板 IVRS/MMIO 映射冲突，导致低端物理内存被意外修改。 | 必须使用专为 Phoenix 平台重写、精确匹配 ACPI 路径的 PNLF 补丁，严禁套用 Intel 笔记本公版。 |
| **💀 死亡案例 5** | **NVRAM 遗留状态**<br>(phxboot.pending 挂起锁) | **连环重启“躺枪”**：明明改回了正确 EFI，开机依然自动重启。 | macOS 脚本在异常崩溃时向主板 NVRAM 写入未完成标志。开机检测到上次未完成，守护进程再次强行重启。 | **修改排错后必须按空格执行一次 `Reset NVRAM`！** 彻底清空主板异常状态位。 |
| **💀 死亡案例 6** | **`ProvideMaxSlide=100`**<br>(内存检索上限约束) | **第二阶段安装报禁止标志 🚫**：报 `Err(0xE) <- EB.MM.AKMR`。 | 强制 OpenCore 仅在 0~200MB 物理内存内检索。第二阶段安装需 748MB 连续内存盘，硬塞碰撞导致内存分配失败中止。 | **必须设为 `ProvideMaxSlide=0`！** 开放全部 256 个 Slide 区间供检索。 |
| **💀 死亡案例 7** | **AMD Zen 4 XHCI 芯片**<br>(USB 中断延迟 Bug) | **几秒动一次超卡假死**：安装界面鼠标肉眼可见几秒才刷新一次。 | 原生 `AppleUSBXHCIPCI` 缺少针对 AMD 控制器的状态轮询唤醒，USB 键盘鼠标数据包在队列中堆积 2~3 秒才批量上报。 | **注入 `XhciNudge.kext` 并添加 `xhcinudge=1` 启动参数！** 主动周期唤醒状态轮询。 |
| **💀 死亡案例 8** | **`Display-Override.kext`**<br>(伪装 AppleBacklightDisplay) | **白苹果进度条过半死锁**：苹果进度条走到 1/3~1/2（显卡切换瞬间）画面永久冻结。 | 驱动强行挂载 `AppleBacklightDisplay` 类到 AMD 780M Framebuffer。AMD DC 缺乏苹果原生背光寄存器支持，引发显示服务空指针崩溃死锁。 | **【铁律】禁止给 AMD 780M 注入此类伪装驱动！**<br>彻底移除该 kext；分辨率与 HiDPI 缩放改用系统用户层工具（如 BetterDisplay）。 |
| **💥 死亡案例 9** | [AMDMicrophone](https://github.com/qhuyduong/AMDMicrophone)<br>（内置数字麦克风） | **OpenCore 阶段加载会导致启动卡死（本机实测）** | 本机测试表明，启动阶段直接加载不稳定，应将驱动部署与 OpenCore 引导分开处理。 | **使用[部署脚本](../scripts/一键部署麦克风.command)，在系统启动后按上游说明操作。** |


