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

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        if Calendar.current.isDateInToday(resetsAt) {
            formatter.dateFormat = "今天 HH:mm"
        } else if Calendar.current.isDateInTomorrow(resetsAt) {
            formatter.dateFormat = "'明天' HH:mm"
        } else {
            formatter.dateFormat = "M月d日 HH:mm"
        }

        return "\(formatter.string(from: resetsAt)) 重置"
    }

    /// 计算时间进度百分比（窗口已过去多少）
    func timeProgress(windowDuration: TimeInterval) -> Double {
        let remaining = resetsAt.timeIntervalSinceNow
        guard remaining > 0, windowDuration > 0 else { return 100.0 }
        let elapsed = windowDuration - remaining
        return min(max(elapsed / windowDuration * 100.0, 0), 100)
    }

    /// 计算 gap = 用量进度 - 时间进度
    /// 正数表示超速，负数表示余量
    func paceGap(windowDuration: TimeInterval) -> Double {
        return utilization - timeProgress(windowDuration: windowDuration)
    }
}

enum PaceStatus {
    case ahead(Double)   // 超速，gap > 5%
    case normal          // 持平，gap ±5% 以内
    case behind(Double)  // 余量，gap < -5%

    static func from(gap: Double) -> PaceStatus {
        if gap > 5 { return .ahead(gap) }
        if gap < -5 { return .behind(gap) }
        return .normal
    }
}

enum UtilizationLevel: Equatable {
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
