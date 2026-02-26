# Claude Watch

macOS 菜单栏应用，实时显示 Claude Code 订阅配额使用情况。

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 功能

- **菜单栏动态图标** — 圆弧仪表盘实时反映用量，>80% 显示警告
- **5h 会话配额** — 当前会话用量百分比 + 具体重置时间
- **7d 每周配额** — 每周限额用量百分比 + 具体重置时间
- **颜色指示** — 绿(<50%) / 黄(50-80%) / 红(>80%)
- **可调刷新频率** — 30秒 / 1分钟 / 2分钟(默认) / 5分钟
- **开机自启** — 一键开关
- **深色模式** — 自动适配

## 安装

### 从源码构建

```bash
# 依赖：Xcode 16+, xcodegen
brew install xcodegen

git clone https://github.com/crowscc/claude-watch.git
cd claude-watch/ClaudeWatch
xcodegen generate
xcodebuild -scheme ClaudeWatch -configuration Release build CONFIGURATION_BUILD_DIR=./build/Release

# 启动
open ./build/Release/Claude\ Watch.app

# (可选) 复制到 Applications
cp -r ./build/Release/Claude\ Watch.app /Applications/
```

### 前置条件

需要已登录 Claude Code CLI：

```bash
claude  # 确保已登录，Keychain 中有凭据
```

## 数据来源

通过 macOS Keychain 读取 Claude Code 的 OAuth token，调用 `https://api.anthropic.com/api/oauth/usage` 获取配额数据。

## 技术栈

- SwiftUI + MenuBarExtra
- Security CLI (Keychain 读取)
- URLSession (API 请求)
- SMAppService (开机自启)
