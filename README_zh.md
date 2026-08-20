# DevPulse

**代码的心跳，始终在视线之内。**

DevPulse 是一个 macOS 菜单栏应用，实时监控你的 [opencode](https://github.com/opencode-ai/opencode) 会话。

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-orange)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)
![Version](https://img.shields.io/badge/version-0.1.1-green)
[![Patreon](https://img.shields.io/badge/support-patreon-orange?logo=patreon&logoColor=white)](https://www.patreon.com/cw/huo_sai)

[English](./README.md) | **中文**

## 系统要求

- macOS 14.0+
- 已安装并运行 [opencode](https://github.com/opencode-ai/opencode)

## 安装

### DMG 安装（推荐）

1. 从 [Releases](https://github.com/albertjiayou0423/devpulse/releases/latest) 下载 `DevPulse.dmg`
2. 打开 DMG，将 DevPulse 拖到 Applications 文件夹
3. 从 Applications 启动应用

### 从源码构建

```bash
git clone https://github.com/albertjiayou0423/devpulse.git
cd devpulse

# 编译
swiftc -O Sources/OpenCodeMonitor/main.swift -o OpenCodeMonitor \
  -Xlinker -lsqlite3 -framework Cocoa -framework ServiceManagement

# 部署到 app bundle
cp OpenCodeMonitor OpenCodeMonitor.app/Contents/MacOS/OpenCodeMonitor

# 运行
open OpenCodeMonitor.app
```

## 使用方法

安装并启动后，DevPulse 会出现在菜单栏：

- **状态条** — 显示当前会话状态，颜色编码指示
- **会话列表** — 点击切换不同的 opencode 会话
- **子代理小点** — 悬停查看子会话详情
- **问题弹窗** — 直接从菜单栏回答 opencode 的问题

### 状态颜色

| 颜色 | 状态 | 含义 |
|------|------|------|
| 🟢 绿色 | 空闲 | 会话就绪，等待输入 |
| 🟣 紫色 | 工作 | 工具执行中 |
| 🔵 青色 | 思考 | 模型推理中 |
| 🟠 橙色 | 压缩 | 上下文压缩进行中 |
| 🔴 红色 | 错误 | 发生错误 |

## 功能特性

- **实时监控** — 追踪你的 opencode 会话运行状态
- **状态指示器** — 工作、思考、空闲、压缩、错误状态的视觉反馈
- **子代理追踪** — 悬停查看所有子会话详情
- **Token 用量** — 一眼掌握上下文窗口消耗
- **问题处理** — 直接从菜单栏回答 opencode 的问题
- **毛玻璃 HUD** — 精美的状态列表界面

## 工作原理

DevPulse 读取 opencode 的 SQLite 数据库 `~/.local/share/opencode/opencode.db`，追踪：

- 会话状态（空闲、工作、思考、压缩、错误）
- Token 用量和上下文窗口消耗
- 子代理关系和状态
- 工具调用及其结果

## 状态颜色

| 颜色 | 状态 | 含义 |
|------|------|------|
| 🟢 绿色 | 空闲 | 会话就绪，等待输入 |
| 🟣 紫色 | 工作 | 工具执行中 |
| 🔵 青色 | 思考 | 模型推理中 |
| 🟠 橙色 | 压缩 | 上下文压缩进行中 |
| 🔴 红色 | 错误 | 发生错误 |

## 开发指南

### 构建

```bash
swiftc -O Sources/OpenCodeMonitor/main.swift -o OpenCodeMonitor \
  -Xlinker -lsqlite3 -framework Cocoa -framework ServiceManagement
```

### 创建 DMG 安装包

```bash
# 安装 create-dmg
brew install create-dmg

# 创建带 Applications 快捷方式和自定义背景的 DMG
create-dmg \
  --volname "DevPulse" \
  --background "assets/dmg-background.png" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --icon "OpenCodeMonitor.app" 200 190 \
  --hide-extension "OpenCodeMonitor.app" \
  --app-drop-link 560 190 \
  "DevPulse.dmg" \
  "OpenCodeMonitor.app"
```

### 项目结构

```
devpulse/
├── Sources/
│   └── OpenCodeMonitor/
│       └── main.swift          # 主应用代码（约 3300 行）
├── OpenCodeMonitor.app/        # App bundle
├── assets/                     # DMG 背景和截图
├── README.md                   # 英文文档
└── README_zh.md                # 中文文档
```

## 路线图

- [ ] iOS 伴侣应用
- [ ] 会话历史时间线
- [ ] Token 用量统计图表
- [ ] 多项目监控
- [ ] 深色/浅色主题支持
- [ ] 键盘快捷键
- [ ] 导出会话数据

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 支持

如果你觉得 DevPulse 有用，可以考虑支持这个项目：

<a href="https://www.patreon.com/cw/huo_sai">
  <img src="https://c5.patreon.com/external/logo/become_a_patron_button@2x.png" width="160">
</a>

## 许可证

MIT © 2026

---

用 ❤️ 为关心代码节奏的开发者而构建。
