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
