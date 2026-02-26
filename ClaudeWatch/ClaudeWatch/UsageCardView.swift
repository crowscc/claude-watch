import SwiftUI

struct UsageCardView: View {
    let title: String
    let window: UsageWindow
    let windowDuration: TimeInterval

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

    private var timeProgress: Double {
        window.timeProgress(windowDuration: windowDuration)
    }

    private var gap: Double {
        window.paceGap(windowDuration: windowDuration)
    }

    private var paceStatus: PaceStatus {
        .from(gap: gap)
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Text("\(Int(window.utilization))%")
                        .font(.title2)
                        .monospacedDigit()
                        .foregroundStyle(tintColor)
                }

                // 双进度条
                VStack(alignment: .leading, spacing: 3) {
                    // 用量进度条
                    HStack(spacing: 4) {
                        ProgressView(value: window.utilization, total: 100)
                            .tint(tintColor)
                        Text("用量")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }

                    // 时间进度条
                    HStack(spacing: 4) {
                        ProgressView(value: timeProgress, total: 100)
                            .tint(.secondary)
                        Text("时间")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }

                // 节奏状态 + 重置时间
                HStack {
                    paceLabel
                    Spacer()
                    Text(window.timeRemainingText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var paceLabel: some View {
        switch paceStatus {
        case .ahead(let g):
            Text("⚡ 超速 +\(Int(g))%")
                .font(.caption)
                .foregroundStyle(.red)
        case .normal:
            Text("✅ 正常")
                .font(.caption)
                .foregroundStyle(.green)
        case .behind(let g):
            Text("💚 余量 \(Int(g))%")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }
}
