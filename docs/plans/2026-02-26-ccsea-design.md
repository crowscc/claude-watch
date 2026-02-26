# CCSEA - Claude Code 配额监控菜单栏应用

## 概述

macOS 原生菜单栏应用，实时显示 Claude Code 订阅配额使用情况（5h 会话窗口、7d 每周限额），帮助用户随时了解剩余额度。

## 技术选型

- **框架**: SwiftUI + MenuBarExtra（macOS 14+）
- **语言**: Swift
- **数据源**: `https://api.anthropic.com/api/oauth/usage`
- **认证**: macOS Keychain 读取 `Claude Code-credentials` 中的 OAuth token

## 数据流

```
macOS Keychain (Claude Code-credentials)
  → 提取 claudeAiOauth.accessToken
  → GET https://api.anthropic.com/api/oauth/usage
    Headers:
      Authorization: Bearer <token>
      anthropic-beta: oauth-2025-04-20
  → 解析 JSON:
      five_hour.utilization (%)
      five_hour.resets_at (ISO timestamp)
      seven_day.utilization (%)
      seven_day.resets_at (ISO timestamp)
  → 更新 UI
  → Timer 每 N 秒重复（默认 120s）
```

## UI 设计

### 菜单栏图标

- 18x18pt 模板图片（template image），仅 alpha 通道
- 造型：圆形仪表盘，弧形填充表示用量
- 右侧文字显示百分比，使用 monospacedDigit 字体
- 图标形态随用量变化：
  - < 50%: 低填充弧形
  - 50%-80%: 中等填充
  - > 80%: 接近满弧 + 感叹号变体

### 弹出面板（Popover）

使用 MenuBarExtra(.window) 样式，宽度 280pt：

- **当前会话 (5h)**: GroupBox 容器，内含 ProgressView(.linear) + 百分比 + 重置倒计时
- **每周限额 (7d)**: 同上结构
- **底部信息**: 上次更新时间 + 手动刷新按钮
- **设置区域**: Divider 分隔
  - 刷新间隔: Stepper 控件（30s/1m/2m/5m）
  - 开机自启: Toggle 开关
  - 退出按钮

### 设计规范

| 元素 | 实现 | 说明 |
|---|---|---|
| 区块容器 | GroupBox | macOS 设置风格分组 |
| 进度条 | ProgressView(.linear) + tint | 绿/黄/红语义色 |
| 百分比 | .title2 + .monospacedDigit | 醒目且不跳动 |
| 重置时间 | .caption + .secondary | 次要信息弱化 |
| 刷新按钮 | SF Symbol arrow.clockwise | 系统图标 |
| 颜色 | .green / .yellow / .red | 系统语义色，自适应深色模式 |

### 交互行为

- 点击菜单栏图标 → popover 弹出
- 点击外部 → 自动关闭
- Token 过期 → 显示 "需要重新登录" 引导
- 网络错误 → 显示缓存数据 + "离线" 标记

## 项目结构

```
CCSEA/
├── CCSEA.xcodeproj
├── CCSEA/
│   ├── CCSEAApp.swift          # 入口 + MenuBarExtra
│   ├── UsageService.swift       # API 请求 + Keychain 读取
│   ├── UsageModel.swift         # 数据模型
│   ├── PopoverView.swift        # 弹出面板 UI
│   ├── MenuBarIcon.swift        # 动态图标渲染
│   └── Assets.xcassets
```

## 配置

- 刷新间隔: 默认 2 分钟，可选 30s/1m/2m/5m
- 持久化: UserDefaults
- 开机自启: SMAppService (ServiceManagement framework)
- 最低系统要求: macOS 14 Sonoma
