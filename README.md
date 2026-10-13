# 冰键 IceKeys

<p align="center">
  <img src="Resources/AppIcon.png" width="144" alt="冰键：蓝白渐变背景上的三个冰块" />
</p>

一个 macOS 原生菜单栏键盘音效 App。按下键盘，播放清脆的冰块音效。

## 功能

- 全局按键音效：授权后，在其他应用中打字也能播放。
- 简单的 SwiftUI 界面：总开关、音量、试听和试打区。
- 可选的长按连续播放，默认关闭。
- 菜单栏控制：暂停、试听、打开窗口和退出。
- 音频预加载、12 路播放节点复用及峰值限制。
- 设置在本机保存；不读取按键字符、不记录输入内容、不联网。
- 蓝白渐变图标，三个冰块 emoji 叠放。

## 环境要求

- macOS 14 或更高版本。
- Xcode 15 或更高版本；当前工程使用 Xcode 27 构建。
- Release 归档已构建 arm64 和 x86_64 两种架构；完整兼容性测试尚未完成。

## 构建与运行

```sh
git clone https://github.com/baitenfurry01/IceKeys.git
cd IceKeys
bash Tools/build.sh
```

构建脚本使用本机签名，并将 `IceKeys.app` 放在仓库的上一级目录。在 `/private/tmp` 中完成构建，以避免文件同步附加的元数据干扰签名。

也可以使用 Xcode 打开 `IceKeys.xcodeproj`，选择 **IceKeys** Scheme 并运行。工程默认使用本地 ad-hoc 签名，启用 App Sandbox；本机开发不需要分发证书。

## 使用方式

1. 打开 App，点击“试听”确认音量。
2. 开启“键盘音效”，在 **系统设置 → 隐私与安全性 → 输入监控** 中允许 IceKeys。
3. 回到 App 点击“重新连接”；若系统要求重新打开 App，按系统提示操作。
4. 关闭窗口后，App 继续在菜单栏运行。通过雪花图标暂停或退出。

授权前，开启音效后可在 App 内的试打框体验。长按连播默认关闭，单独按下 Shift、Control、Option、Command 等修饰键不触发音效。锁屏、安全输入及受系统保护的输入场景可能阻止全局监听。

重新编译、移动 App 或更换签名后，macOS 可能要求重新授予输入监控权限。

## 项目结构

| 路径 | 内容 |
| --- | --- |
| `Sources/IceKeysApp.swift` | 应用生命周期和菜单栏 |
| `Sources/ContentView.swift` | SwiftUI 主界面 |
| `Sources/AppModel.swift` | 状态、权限和本机设置 |
| `Sources/KeyboardListener.swift` | 被动 keyDown 监听及应用内回退 |
| `Sources/AudioPlayer.swift` | 预加载、音效播放与设备变化恢复 |
| `Resources/ice.wav` | 内置冰块音效，约 0.666 秒 |
| `Resources/AppIcon.png`、`AppIcon.icns` | 应用图标 |
| `Resources/PrivacyInfo.xcprivacy` | 隐私清单 |
| `Tools/MakeIcon.swift` | 图标生成源码 |
| `Tools/build.sh` | 本机构建脚本 |

## 隐私

全局监听只判断是否按下按键及是否为长按重复，不读取字符、键码或前台应用。试打框文字仅临时保存在内存中，可随时清空。App 不上传数据，也不包含分析或广告 SDK。

## App Store 构建

版本 **1.0（构建 1）** 已上传 App Store Connect，尚未提交审核或公开上架。上传成功不代表审核已通过。

若使用自己的开发者账号发布，请配置自己的 Bundle ID、开发者团队和签名。`ExportOptions-AppStore.example.plist` 为模板，复制为 `ExportOptions-AppStore.plist` 后填入自己的 Team ID。实际导出配置、证书、私钥、描述文件及构建产物均不纳入版本控制。

本仓库包含开发源码与素材，尚未提供经过 Developer ID 签名及公证的独立安装包。
