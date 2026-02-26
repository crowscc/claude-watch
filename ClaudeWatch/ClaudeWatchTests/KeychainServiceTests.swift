import XCTest
@testable import ClaudeWatch

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
