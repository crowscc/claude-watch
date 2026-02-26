# CCSEA Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 构建一个 macOS 原生菜单栏应用，实时显示 Claude Code 订阅配额（5h/7d）使用情况。

**Architecture:** SwiftUI MenuBarExtra 单窗口应用，通过 macOS Keychain 获取 OAuth token，定时轮询 Anthropic 使用量 API，动态渲染菜单栏图标和弹出面板。

**Tech Stack:** Swift 6.2, SwiftUI, MenuBarExtra, Security.framework, ServiceManagement.framework, XcodeGen

---

### Task 1: 项目脚手架

**Files:**
- Create: `CCSEA/project.yml`
- Create: `CCSEA/CCSEA/CCSEAApp.swift`
- Create: `CCSEA/CCSEA/Info.plist`
- Create: `CCSEA/CCSEA/CCSEA.entitlements`

**Step 1: 安装 xcodegen**

Run: `brew install xcodegen`
Expected: xcodegen 安装成功

**Step 2: 创建目录结构**

Run:
```bash
mkdir -p CCSEA/CCSEA
mkdir -p CCSEA/CCSEATests
```

**Step 3: 创建 project.yml**

```yaml
name: CCSEA
options:
  bundleIdPrefix: com.ccsea
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "16.0"
settings:
  base:
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "14.0"
targets:
  CCSEA:
    type: application
    platform: macOS
    sources:
      - CCSEA
    settings:
      base:
        INFOPLIST_FILE: CCSEA/Info.plist
        CODE_SIGN_ENTITLEMENTS: CCSEA/CCSEA.entitlements
        PRODUCT_BUNDLE_IDENTIFIER: com.ccsea.app
        PRODUCT_NAME: CCSEA
    info:
      path: CCSEA/Info.plist
      properties:
        LSUIElement: true
        CFBundleName: CCSEA
        CFBundleDisplayName: CCSEA
        CFBundleShortVersionString: "1.0.0"
        CFBundleVersion: "1"
  CCSEATests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - CCSEATests
    dependencies:
      - target: CCSEA
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ccsea.tests
```

**Step 4: 创建 Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

> `LSUIElement = true` 让应用只出现在菜单栏，不显示在 Dock。

**Step 5: 创建 entitlements**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

> 关闭沙盒以便访问 Keychain 中 Claude Code 存储的凭据。启用网络出站。

**Step 6: 创建最小 App 入口**

```swift
import SwiftUI

@main
struct CCSEAApp: App {
    var body: some Scene {
        MenuBarExtra("CCSEA", systemImage: "gauge.medium") {
            Text("Hello CCSEA")
            Divider()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Step 7: 生成 Xcode 项目并构建验证**

Run:
```bash
cd CCSEA && xcodegen generate
xcodebuild -project CCSEA.xcodeproj -scheme CCSEA -configuration Debug build
```
Expected: BUILD SUCCEEDED，菜单栏出现 gauge 图标

**Step 8: 初始化 Git 并提交**

```bash
cd .. && git init
echo ".DS_Store\nCCSEA/build/\nCCSEA/CCSEA.xcodeproj/xcuserdata/\nCCSEA/CCSEA.xcodeproj/project.xcworkspace/xcuserdata/" > .gitignore
git add -A && git commit -m "feat: scaffold CCSEA menu bar app with xcodegen"
```

---

### Task 2: 数据模型

**Files:**
- Create: `CCSEA/CCSEA/UsageModel.swift`
- Create: `CCSEA/CCSEATests/UsageModelTests.swift`

**Step 1: 写失败测试**

```swift
import XCTest
@testable import CCSEA

final class UsageModelTests: XCTestCase {

    func testDecodeUsageResponse() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 23.0,
                "resets_at": "2026-02-26T12:00:00+00:00"
            },
            "seven_day": {
                "utilization": 14.0,
                "resets_at": "2026-03-01T08:00:00+00:00"
            }
        }
        """.data(using: .utf8)!

        let usage = try JSONDecoder.apiDecoder.decode(UsageResponse.self, from: json)
        XCTAssertEqual(usage.fiveHour.utilization, 23.0)
        XCTAssertEqual(usage.sevenDay.utilization, 14.0)
        XCTAssertNotNil(usage.fiveHour.resetsAt)
        XCTAssertNotNil(usage.sevenDay.resetsAt)
    }

    func testUtilizationLevel() {
        XCTAssertEqual(UtilizationLevel.from(percentage: 30), .normal)
        XCTAssertEqual(UtilizationLevel.from(percentage: 60), .warning)
        XCTAssertEqual(UtilizationLevel.from(percentage: 85), .critical)
    }

    func testTimeRemainingFormatting() {
        let future = Date().addingTimeInterval(3600 + 660) // 1h 11min
        let window = UsageWindow(utilization: 23.0, resetsAt: future)
        let remaining = window.timeRemainingText
        XCTAssertTrue(remaining.contains("1"))
        XCTAssertTrue(remaining.contains("小时") || remaining.contains("h"))
    }
}
```

**Step 2: 运行测试确认失败**

Run: `cd CCSEA && xcodebuild test -project CCSEA.xcodeproj -scheme CCSEATests -destination 'platform=macOS' 2>&1 | tail -5`
Expected: 编译失败 — UsageResponse 未定义

**Step 3: 实现数据模型**

```swift
import Foundation

struct UsageResponse: Codable {
    let fiveHour: UsageWindow
    let sevenDay: UsageWindow

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }
}

struct UsageWindow: Codable {
    let utilization: Double
    let resetsAt: Date

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    var timeRemainingText: String {
        let interval = resetsAt.timeIntervalSinceNow
        guard interval > 0 else { return "即将重置" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours) 小时 \(minutes) 分钟后重置"
        } else {
            return "\(minutes) 分钟后重置"
        }
    }
}

enum UtilizationLevel {
    case normal   // < 50%
    case warning  // 50-80%
    case critical // > 80%

    static func from(percentage: Double) -> UtilizationLevel {
        switch percentage {
        case ..<50: return .normal
        case 50..<80: return .warning
        default: return .critical
        }
    }

    var color: String {
        switch self {
        case .normal: return "green"
        case .warning: return "yellow"
        case .critical: return "red"
        }
    }
}

extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
```

**Step 4: 运行测试确认通过**

Run: `xcodebuild test -project CCSEA.xcodeproj -scheme CCSEATests -destination 'platform=macOS' 2>&1 | grep -E "Test (Suite|Case|session)" | tail -10`
Expected: 3 tests passed

**Step 5: 提交**

```bash
git add -A && git commit -m "feat: add UsageModel with JSON decoding and utilization levels"
```

---

### Task 3: Keychain 服务

**Files:**
- Create: `CCSEA/CCSEA/KeychainService.swift`
- Create: `CCSEA/CCSEATests/KeychainServiceTests.swift`

**Step 1: 写失败测试**

```swift
import XCTest
@testable import CCSEA

final class KeychainServiceTests: XCTestCase {

    func testParseCredentialsJSON() throws {
        let json = """
        {
            "claudeAiOauth": {
                "accessToken": "sk-ant-oat01-test-token-123",
                "refreshToken": "sk-ant-ort01-refresh-456",
                "expiresAt": "2026-03-01T00:00:00Z"
            }
        }
        """
        let token = try KeychainService.parseAccessToken(from: json)
        XCTAssertEqual(token, "sk-ant-oat01-test-token-123")
    }

    func testParseInvalidJSON() {
        XCTAssertThrowsError(try KeychainService.parseAccessToken(from: "not json")) { error in
            XCTAssertTrue(error is KeychainService.KeychainError)
        }
    }

    func testParseMissingToken() {
        let json = """
        {"claudeAiOauth": {}}
        """
        XCTAssertThrowsError(try KeychainService.parseAccessToken(from: json)) { error in
            XCTAssertTrue(error is KeychainService.KeychainError)
        }
    }
}
```

**Step 2: 运行测试确认失败**

Run: `xcodebuild test -project CCSEA.xcodeproj -scheme CCSEATests -destination 'platform=macOS' 2>&1 | tail -5`
Expected: 编译失败

**Step 3: 实现 KeychainService**

```swift
import Foundation
import Security

enum KeychainService {

    enum KeychainError: LocalizedError {
        case notFound
        case invalidData
        case missingToken
        case securityError(OSStatus)

        var errorDescription: String? {
            switch self {
            case .notFound: return "Keychain 中未找到 Claude Code 凭据"
            case .invalidData: return "凭据数据格式无效"
            case .missingToken: return "凭据中缺少 accessToken"
            case .securityError(let status): return "Keychain 错误: \(status)"
            }
        }
    }

    static func getAccessToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.securityError(status)
        }

        guard let data = result as? Data,
              let jsonString = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return try parseAccessToken(from: jsonString)
    }

    static func parseAccessToken(from jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let parsed: [String: [String: Any]]
        do {
            guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let oauth = obj["claudeAiOauth"] as? [String: Any] else {
                throw KeychainError.invalidData
            }
            parsed = ["claudeAiOauth": oauth]
        } catch is KeychainError {
            throw KeychainError.invalidData
        } catch {
            throw KeychainError.invalidData
        }

        guard let token = parsed["claudeAiOauth"]?["accessToken"] as? String,
              !token.isEmpty else {
            throw KeychainError.missingToken
        }

        return token
    }
}
```

**Step 4: 运行测试确认通过**

Run: `xcodebuild test -project CCSEA.xcodeproj -scheme CCSEATests -destination 'platform=macOS' 2>&1 | grep -E "Test (Suite|Case|session)" | tail -10`
Expected: 全部通过

**Step 5: 提交**

```bash
git add -A && git commit -m "feat: add KeychainService for reading Claude Code OAuth token"
```

---

### Task 4: API 服务

**Files:**
- Create: `CCSEA/CCSEA/UsageService.swift`
- Create: `CCSEA/CCSEATests/UsageServiceTests.swift`

**Step 1: 写失败测试**

```swift
import XCTest
@testable import CCSEA

final class UsageServiceTests: XCTestCase {

    func testBuildRequest() throws {
        let request = try UsageService.buildRequest(token: "test-token-123")
        XCTAssertEqual(request.url?.absoluteString, "https://api.anthropic.com/api/oauth/usage")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token-123")
        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-beta"), "oauth-2025-04-20")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testParseAPIResponse() throws {
        let json = """
        {
            "five_hour": { "utilization": 45.5, "resets_at": "2026-02-26T18:00:00+00:00" },
            "seven_day": { "utilization": 12.3, "resets_at": "2026-03-01T08:00:00+00:00" }
        }
        """.data(using: .utf8)!

        let usage = try UsageService.parseResponse(data: json)
        XCTAssertEqual(usage.fiveHour.utilization, 45.5, accuracy: 0.01)
        XCTAssertEqual(usage.sevenDay.utilization, 12.3, accuracy: 0.01)
    }
}
```

**Step 2: 运行测试确认失败**

Expected: 编译失败 — UsageService 未定义

**Step 3: 实现 UsageService**

```swift
import Foundation

enum UsageService {

    enum ServiceError: LocalizedError {
        case invalidResponse
        case httpError(Int)
        case tokenExpired

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "API 响应格式无效"
            case .httpError(let code): return "HTTP 错误: \(code)"
            case .tokenExpired: return "OAuth token 已过期，请在终端运行 claude 重新登录"
            }
        }
    }

    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    static func buildRequest(token: String) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = 15
        return request
    }

    static func parseResponse(data: Data) throws -> UsageResponse {
        return try JSONDecoder.apiDecoder.decode(UsageResponse.self, from: data)
    }

    static func fetch() async throws -> UsageResponse {
        let token = try KeychainService.getAccessToken()
        let request = try buildRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw ServiceError.tokenExpired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.httpError(httpResponse.statusCode)
        }

        return try parseResponse(data: data)
    }
}
```

**Step 4: 运行测试确认通过**

Run: `xcodebuild test -project CCSEA.xcodeproj -scheme CCSEATests -destination 'platform=macOS' 2>&1 | grep -E "Test (Suite|Case|session)" | tail -10`
Expected: 全部通过

**Step 5: 提交**

```bash
git add -A && git commit -m "feat: add UsageService for fetching quota from Anthropic API"
```

---

### Task 5: ViewModel — 状态管理

**Files:**
- Create: `CCSEA/CCSEA/UsageViewModel.swift`

**Step 1: 实现 ViewModel**

```swift
import Foundation
import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded(UsageResponse)
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading): return true
            case (.loaded(let a), .loaded(let b)):
                return a.fiveHour.utilization == b.fiveHour.utilization
                    && a.sevenDay.utilization == b.sevenDay.utilization
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    @Published var state: State = .idle
    @Published var lastUpdated: Date?

    @AppStorage("refreshInterval") var refreshInterval: Double = 120

    private var timer: Timer?

    var usage: UsageResponse? {
        if case .loaded(let u) = state { return u }
        return nil
    }

    var isTokenExpired: Bool {
        if case .error(let msg) = state { return msg.contains("token") || msg.contains("登录") }
        return false
    }

    func startPolling() {
        fetch()
        scheduleTimer()
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetch()
            }
        }
    }

    func fetch() {
        Task {
            state = .loading
            do {
                let response = try await UsageService.fetch()
                state = .loaded(response)
                lastUpdated = Date()
            } catch {
                // 保留上次成功数据，仅在无数据时显示错误
                if usage == nil {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }
}
```

**Step 2: 构建验证**

Run: `xcodebuild -project CCSEA.xcodeproj -scheme CCSEA build 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

**Step 3: 提交**

```bash
git add -A && git commit -m "feat: add UsageViewModel with polling and state management"
```

---

### Task 6: 动态菜单栏图标

**Files:**
- Create: `CCSEA/CCSEA/MenuBarIcon.swift`

**Step 1: 实现动态图标渲染**

```swift
import SwiftUI

struct MenuBarIcon {

    static func render(utilization: Double) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = 7.0
            let lineWidth: CGFloat = 2.0

            // 背景圆环
            let bgPath = NSBezierPath()
            bgPath.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: 0,
                endAngle: 360
            )
            bgPath.lineWidth = lineWidth
            NSColor.tertiaryLabelColor.setStroke()
            bgPath.stroke()

            // 用量弧形 — 从 12 点方向顺时针
            let startAngle: CGFloat = 90
            let sweep = CGFloat(utilization / 100.0) * 360.0
            let endAngle = startAngle - sweep

            if utilization > 0 {
                let fgPath = NSBezierPath()
                fgPath.appendArc(
                    withCenter: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
                fgPath.lineWidth = lineWidth
                fgPath.lineCapStyle = .round
                NSColor.labelColor.setStroke()
                fgPath.stroke()
            }

            // > 80% 时中心画感叹号
            if utilization > 80 {
                let exclamation = NSBezierPath()
                // 竖线
                exclamation.move(to: CGPoint(x: center.x, y: center.y + 3))
                exclamation.line(to: CGPoint(x: center.x, y: center.y - 1))
                exclamation.lineWidth = 1.5
                exclamation.lineCapStyle = .round
                NSColor.labelColor.setStroke()
                exclamation.stroke()
                // 圆点
                let dot = NSBezierPath(
                    ovalIn: NSRect(x: center.x - 0.75, y: center.y - 3.5, width: 1.5, height: 1.5)
                )
                NSColor.labelColor.setFill()
                dot.fill()
            }

            return true
        }
        image.isTemplate = true  // 关键：模板图片自动适配亮/暗模式
        return image
    }
}
```

**Step 2: 构建验证**

Run: `xcodebuild -project CCSEA.xcodeproj -scheme CCSEA build 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

**Step 3: 提交**

```bash
git add -A && git commit -m "feat: add dynamic menu bar icon with arc gauge rendering"
```

---

### Task 7: 弹出面板 UI

**Files:**
- Create: `CCSEA/CCSEA/PopoverView.swift`
- Create: `CCSEA/CCSEA/UsageCardView.swift`

**Step 1: 创建用量卡片组件**

```swift
import SwiftUI

struct UsageCardView: View {
    let title: String
    let window: UsageWindow

    private var level: UtilizationLevel {
        .from(percentage: window.utilization)
    }

    private var tintColor: Color {
        switch level {
        case .normal: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Text("\(Int(window.utilization))%")
                        .font(.title2)
                        .monospacedDigit()
                        .foregroundStyle(tintColor)
                }

                ProgressView(value: window.utilization, total: 100)
                    .tint(tintColor)

                Text(window.timeRemainingText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

**Step 2: 创建弹出面板主视图**

```swift
import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: UsageViewModel

    private let intervals: [(String, Double)] = [
        ("30 秒", 30),
        ("1 分钟", 60),
        ("2 分钟", 120),
        ("5 分钟", 300),
    ]

    @State private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text("Claude Code Usage")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.fetch() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.state == .loading)
            }

            // 内容区
            switch viewModel.state {
            case .idle, .loading:
                if let usage = viewModel.usage {
                    usageCards(usage)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            case .loaded(let usage):
                usageCards(usage)
            case .error(let message):
                errorView(message)
            }

            // 上次更新
            if let lastUpdated = viewModel.lastUpdated {
                Text("上次更新：\(lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // 设置区
            HStack {
                Image(systemName: "gear")
                    .foregroundStyle(.secondary)
                Text("刷新间隔")
                Spacer()
                Picker("", selection: $viewModel.refreshInterval) {
                    ForEach(intervals, id: \.1) { name, value in
                        Text(name).tag(value)
                    }
                }
                .labelsHidden()
                .frame(width: 90)
                .onChange(of: viewModel.refreshInterval) {
                    viewModel.scheduleTimer()
                }
            }

            Divider()

            Button("退出 CCSEA") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    @ViewBuilder
    private func usageCards(_ usage: UsageResponse) -> some View {
        UsageCardView(title: "当前会话 (5h)", window: usage.fiveHour)
        UsageCardView(title: "每周限额 (7d)", window: usage.sevenDay)
    }

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        GroupBox {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                if viewModel.isTokenExpired {
                    Text("请在终端运行 `claude` 重新登录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
        }
    }
}
```

**Step 3: 构建验证**

Run: `xcodebuild -project CCSEA.xcodeproj -scheme CCSEA build 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

**Step 4: 提交**

```bash
git add -A && git commit -m "feat: add PopoverView and UsageCardView with Apple HIG styling"
```

---

### Task 8: 集成 App 入口

**Files:**
- Modify: `CCSEA/CCSEA/CCSEAApp.swift`

**Step 1: 更新 App 入口，串联所有组件**

```swift
import SwiftUI

@main
struct CCSEAApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(viewModel: viewModel)
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 4) {
            if let usage = viewModel.usage {
                Image(nsImage: MenuBarIcon.render(utilization: usage.fiveHour.utilization))
                Text("\(Int(usage.fiveHour.utilization))%")
                    .monospacedDigit()
            } else {
                Image(systemName: "gauge.medium")
                Text("--")
            }
        }
        .onAppear {
            viewModel.startPolling()
        }
    }
}
```

**Step 2: 构建并运行测试**

Run:
```bash
xcodebuild -project CCSEA.xcodeproj -scheme CCSEA build 2>&1 | tail -3
xcodebuild test -project CCSEA.xcodeproj -scheme CCSEATests -destination 'platform=macOS' 2>&1 | grep -E "Test (Suite|Case|session|Executed)" | tail -10
```
Expected: BUILD SUCCEEDED + 全部测试通过

**Step 3: 提交**

```bash
git add -A && git commit -m "feat: integrate all components in CCSEAApp entry point"
```

---

### Task 9: 开机自启动

**Files:**
- Modify: `CCSEA/CCSEA/PopoverView.swift`

**Step 1: 在 PopoverView 设置区添加开机自启**

在 PopoverView 的设置区 Divider 前添加：

```swift
// 添加 import
import ServiceManagement

// 在 "刷新间隔" HStack 之后添加:
HStack {
    Image(systemName: "rocket")
        .foregroundStyle(.secondary)
    Text("开机自启")
    Spacer()
    Toggle("", isOn: $launchAtLogin)
        .labelsHidden()
        .onChange(of: launchAtLogin) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = !launchAtLogin
            }
        }
}
.onAppear {
    launchAtLogin = (SMAppService.mainApp.status == .enabled)
}
```

**Step 2: 构建验证**

Run: `xcodebuild -project CCSEA.xcodeproj -scheme CCSEA build 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

**Step 3: 提交**

```bash
git add -A && git commit -m "feat: add launch-at-login toggle using SMAppService"
```

---

### Task 10: 端到端验证 & 最终打包

**Step 1: 运行全部测试**

Run: `xcodebuild test -project CCSEA.xcodeproj -scheme CCSEATests -destination 'platform=macOS' 2>&1 | grep -E "Executed|FAIL"`
Expected: 全部通过，无 FAIL

**Step 2: 构建 Release 版本**

Run:
```bash
xcodebuild -project CCSEA.xcodeproj -scheme CCSEA -configuration Release build \
  CONFIGURATION_BUILD_DIR=./build/Release 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED，`build/Release/CCSEA.app` 生成

**Step 3: 手动验证清单**

- [ ] 打开 CCSEA.app → 菜单栏出现图标 + 百分比
- [ ] 点击图标 → 弹出面板显示 5h 和 7d 用量
- [ ] 进度条颜色正确（绿/黄/红）
- [ ] 重置倒计时正确显示
- [ ] 刷新按钮可用
- [ ] 切换刷新间隔生效
- [ ] 亮色/暗色模式切换正常
- [ ] 退出按钮正常工作

**Step 4: 最终提交**

```bash
git add -A && git commit -m "chore: final build verification and cleanup"
```
