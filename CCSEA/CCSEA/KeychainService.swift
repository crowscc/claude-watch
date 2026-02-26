import Foundation
import Security

enum KeychainService {

    enum KeychainError: LocalizedError {
        case notFound
        case invalidData
        case missingToken
        case securityError(OSStatus)

        var errorDescription: String? {
            switch self {
            case .notFound: return "Keychain 中未找到 Claude Code 凭据"
            case .invalidData: return "凭据数据格式无效"
            case .missingToken: return "凭据中缺少 accessToken"
            case .securityError(let status): return "Keychain 错误: \(status)"
            }
        }
    }

    static func getAccessToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.securityError(status)
        }

        guard let data = result as? Data,
              let jsonString = String(data: data, encoding: .utf8) else {
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
