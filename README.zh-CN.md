# NowThere

[English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

<p align="center">
  <img src="docs/assets/nowthere-intro.png" alt="NowThere 介绍图，展示 macOS 菜单栏中的东京时区时钟" width="900">
</p>

菜单栏知道你的本地时间。现在，它也知道那里的时间。

NowThere 是一个原生 macOS 菜单栏时钟，用来随时查看一个重要时区。它提供本地化、可配置的菜单栏标题，并且不会出现在 Dock 中。

`scripts/build-app-bundle.sh debug` | `open .build/debug/NowThere.app`

---

## 为什么是 NowThere？

远程协作、旅行计划、发布窗口、会议和朋友，经常不在你的本地时区。NowThere 把一个选定地点放进 macOS 菜单栏，用适合快速扫读的格式显示，不需要打开日历、时钟或浏览器。

它刻意保持小而专注：一个选定时区，一个紧凑标题，系统时区搜索，英文、简体中文、日文界面，以及包含详细信息的菜单。

## 日常使用场景

- 在站会、排期和交接前，始终看得到远程团队所在城市的时间。
- 查看发布窗口、客户会议、旅行计划或家人时间时，不需要在脑中换算。
- 给时钟设置 `工作`、`家庭` 或客户名这样的自定义标签，让菜单栏更贴近自己的语境。

## 亮点

### 一个始终可见的时钟

NowThere 会在菜单栏直接显示紧凑的文本时钟，例如：

```text
Tokyo Jul 08 Wed 12:34
```

标题按分钟边界更新，稳定显示，不会每秒跳动。

### 搜索所有系统时区

从 macOS 的完整时区列表中选择。可以按城市名搜索，例如 `Tokyo`，也可以按 IANA 标识符搜索，例如 `Asia/Tokyo`。

### 自定义菜单栏标题

每个标题字段都可以独立开关：

- 城市/标签
- 日期
- 星期
- 时间

如果所有字段都关闭，NowThere 会回退显示应用名，避免菜单栏项目变成空白。

也可以选择适合自己的标题样式：

- 默认
- 时间优先
- 分隔显示
- 括号显示

支持 24 小时制或 12 小时制，并可以添加 `工作`、`家庭`、客户名等自定义标签。

### 使用你的语言

应用界面可以在系统语言、英文、简体中文、日文之间切换。菜单面板和菜单栏标题中的日期/星期会一起更新。

### 点击查看详情

打开菜单后，可以看到选中时区的完整信息：

- 城市标签
- IANA 时区标识符
- 完整日期
- 完整星期
- 时间
- UTC 偏移

### 原生 macOS

NowThere 是一个轻量 AppKit + SwiftUI 菜单栏应用。它使用原生 `NSStatusItem` 和瞬态弹出面板，通过 `UserDefaults` 保存偏好，支持登录时启动，并以 `LSUIElement` 应用形式打包，所以不会出现在 Dock 中。

## 安装

目前还没有签名发布版本。可以在本地构建并运行：

```bash
scripts/build-app-bundle.sh debug
open .build/debug/NowThere.app
```

如果已有旧版本正在运行：

```bash
pkill NowThere
open .build/debug/NowThere.app
```

## 系统要求

- macOS 13+
- 带 Swift 6 工具链的 Xcode

本项目在 macOS 26.4.1 和 Xcode 26.5 上构建并测试通过。

## 开发者

构建可执行文件：

```bash
swift build --product NowThere
```

运行测试：

```bash
swift test
```

构建 app bundle：

```bash
scripts/build-app-bundle.sh debug
```

验证菜单栏应用标记：

```bash
/usr/libexec/PlistBuddy -c "Print :LSUIElement" .build/debug/NowThere.app/Contents/Info.plist
```

期望输出：

```text
true
```

## 当前范围

NowThere 当前专注于一个选定时区。它暂不支持多个时钟、秒级更新或自定义格式模板。

## License

NowThere 使用 MIT License 发布。详见 [LICENSE](LICENSE)。
