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
