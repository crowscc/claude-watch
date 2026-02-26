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

                // 用量进度条
                ProgressView(value: window.utilization, total: 100)
                    .tint(tintColor)

                // 时间进度标记条
                PaceIndicator(
                    utilization: window.utilization,
                    timeProgress: timeProgress,
                    tintColor: tintColor
                )

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

/// 对比指示条：显示用量位置 ▲ 和时间位置 △
struct PaceIndicator: View {
    let utilization: Double
    let timeProgress: Double
    let tintColor: Color

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usageX = width * min(utilization, 100) / 100
            let timeX = width * min(timeProgress, 100) / 100

            ZStack(alignment: .leading) {
                // 底线
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 2)

                // 时间进度标记 △（空心三角）
                Triangle()
                    .stroke(Color.secondary, lineWidth: 1)
                    .frame(width: 6, height: 5)
                    .offset(x: timeX - 3, y: -1)

                // 用量标记 ▲（实心三角）
                Triangle()
                    .fill(tintColor)
                    .frame(width: 6, height: 5)
                    .offset(x: usageX - 3, y: -1)
            }
        }
        .frame(height: 6)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
