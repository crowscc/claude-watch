import Foundation

enum KeychainService {

    enum KeychainError: LocalizedError {
        case notFound
        case invalidData
        case missingToken
        case commandFailed(String)

        var errorDescription: String? {
            switch self {
            case .notFound: return "Keychain 中未找到 Claude Code 凭据"
            case .invalidData: return "凭据数据格式无效"
            case .missingToken: return "凭据中缺少 accessToken"
            case .commandFailed(let msg): return "Keychain 读取失败: \(msg)"
            }
        }
    }

    static func getAccessToken() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = [
            "find-generic-password",
            "-s", "Claude Code-credentials",
            "-a", NSUserName(),
            "-w"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw KeychainError.notFound
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let jsonString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !jsonString.isEmpty else {
            throw KeychainError.invalidData
        }

        return try parseAccessToken(from: jsonString)
    }

    static func parseAccessToken(from jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let parsed: [String: Any]
        do {
            guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw KeychainError.invalidData
            }
            parsed = obj
        } catch is KeychainError {
            throw KeychainError.invalidData
        } catch {
            throw KeychainError.invalidData
        }

        guard let oauth = parsed["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String,
              !token.isEmpty else {
            throw KeychainError.missingToken
        }

        return token
    }
}
