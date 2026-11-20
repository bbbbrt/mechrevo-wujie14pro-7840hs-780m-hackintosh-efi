# SMBIOS 配置指南

本仓库的公开 EFI 不包含任何真实设备的 SMBIOS 序列号。EFI/OC/config.plist 中以下字段故意留空或置为全零模板：

- PlatformInfo -> Generic -> SystemSerialNumber
- PlatformInfo -> Generic -> MLB
- PlatformInfo -> Generic -> ROM
- PlatformInfo -> Generic -> SystemUUID

首次启动前，使用 GenSMBIOS 为 MacBookPro16,1 生成属于自己的唯一值，并写回上述字段。不要复制作者或其他用户的序列号、主板序列号、ROM 或 UUID；也不要把个人 config.plist 提交到公开仓库。

生成工具：https://github.com/corpnewt/GenSMBIOS

生成发布包或提交前，请再次检查 config.plist、release ZIP 和截图中均没有真实 SMBIOS 值。
