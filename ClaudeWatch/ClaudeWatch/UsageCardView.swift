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
