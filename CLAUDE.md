# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Watch — macOS 菜单栏应用，实时监控 Claude Code 订阅配额（5小时会话 + 7天周配额）。通过 Keychain 读取 OAuth token，调用 Anthropic API 获取用量数据，以动态图表展示。

## Build Commands

```bash
# 前提：brew install xcodegen

# 开发构建（生成项目 → 编译 → 安装到 /Applications → 自动启动）
./build.sh

# 发布构建（双架构 DMG）
./build.sh release [VERSION]

# 仅生成 Xcode 项目
cd ClaudeWatch && xcodegen generate

# 运行测试
xcodebuild test -project ClaudeWatch/ClaudeWatch.xcodeproj -scheme ClaudeWatch -destination 'platform=macOS'
```

## Architecture (MVVM)

```
ClaudeWatchApp (入口, MenuBarExtra)
  ├── MenuBarIcon          — 18×18 圆弧仪表盘图标（NSBezierPath 绘制）
  ├── PopoverView          — 弹出面板主视图
  │   └── UsageCardView    — 配额卡片（双进度条：用量 vs 时间）
  └── UsageViewModel       — @MainActor 状态管理 + 定时轮询
      └── UsageService     — HTTP 请求（async/await + URLSession）
          └── KeychainService — 通过 /usr/bin/security CLI 读取 Keychain token
```

**数据流**：Timer → ViewModel.fetch() → KeychainService 取 token → UsageService 调 API → 解码 UsageResponse → @Published 驱动 UI 更新

**核心模型** (`UsageModel.swift`)：
- `UsageResponse` — API 响应（five_hour / seven_day 两个窗口）
- `UsageWindow` — utilization%、resets_at、timeProgress()、paceGap() 节奏对比算法
- `PaceStatus` — ahead/normal/behind 状态枚举

**关键设计决策**：
- 网络失败时保留缓存数据继续展示，防止 UI 闪烁
- 禁用 App Sandbox（需要访问 Keychain + 网络）
- 菜单栏图标使用 isTemplate=true 自动适配深色/浅色模式
- 刷新间隔通过 @AppStorage 持久化，默认 120 秒

## Tech Stack

- Swift 5.9+ / SwiftUI / macOS 14.0+
- xcodegen 生成 Xcode 项目（`ClaudeWatch/project.yml`）
- SMAppService 管理开机自启
- XCTest 单元测试

## Project Structure

源码在 `ClaudeWatch/ClaudeWatch/`，测试在 `ClaudeWatch/ClaudeWatchTests/`，构建产物在 `ClaudeWatch/build/`。
