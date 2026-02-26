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
