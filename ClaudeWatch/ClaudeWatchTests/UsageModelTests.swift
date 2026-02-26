import XCTest
@testable import ClaudeWatch

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
        let future = Date().addingTimeInterval(3600 + 660) // 1h 11min from now
        let window = UsageWindow(utilization: 23.0, resetsAt: future)
        let remaining = window.timeRemainingText
        XCTAssertTrue(remaining.contains("重置"))
        XCTAssertTrue(remaining.contains(":")) // 包含具体时间如 "HH:mm"
    }

    func testTimeRemainingExpired() {
        let past = Date().addingTimeInterval(-60)
        let window = UsageWindow(utilization: 23.0, resetsAt: past)
        XCTAssertEqual(window.timeRemainingText, "即将重置")
    }
}
