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

    // MARK: - Pace Gap 测试

    func testTimeProgressHalfway() {
        // 5h 窗口，剩余 2.5h = 过了一半
        let window = UsageWindow(utilization: 50.0, resetsAt: Date().addingTimeInterval(2.5 * 3600))
        let progress = window.timeProgress(windowDuration: 5 * 3600)
        XCTAssertEqual(progress, 50.0, accuracy: 1.0)
    }

    func testPaceGapAhead() {
        // 用了 60%，时间过了 40% → 超速 +20%
        let window = UsageWindow(utilization: 60.0, resetsAt: Date().addingTimeInterval(3 * 3600))
        let gap = window.paceGap(windowDuration: 5 * 3600)
        XCTAssertEqual(gap, 20.0, accuracy: 1.0)
    }

    func testPaceGapBehind() {
        // 用了 20%，时间过了 60% → 余量 -40%
        let window = UsageWindow(utilization: 20.0, resetsAt: Date().addingTimeInterval(2 * 3600))
        let gap = window.paceGap(windowDuration: 5 * 3600)
        XCTAssertEqual(gap, -40.0, accuracy: 1.0)
    }

    func testPaceStatusNormal() {
        let status = PaceStatus.from(gap: 3.0)
        if case .normal = status {} else { XCTFail("Expected .normal") }
    }

    func testPaceStatusAhead() {
        let status = PaceStatus.from(gap: 15.0)
        if case .ahead(let g) = status { XCTAssertEqual(g, 15.0) } else { XCTFail("Expected .ahead") }
    }

    func testPaceStatusBehind() {
        let status = PaceStatus.from(gap: -20.0)
        if case .behind(let g) = status { XCTAssertEqual(g, -20.0) } else { XCTFail("Expected .behind") }
    }
}
