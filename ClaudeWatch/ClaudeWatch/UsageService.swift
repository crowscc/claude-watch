import Foundation

enum UsageService {

    enum ServiceError: LocalizedError {
        case invalidResponse
        case httpError(Int)
        case tokenExpired

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "API 响应格式无效"
            case .httpError(let code): return "HTTP 错误: \(code)"
            case .tokenExpired: return "OAuth token 已过期，请在终端运行 claude 重新登录"
            }
        }
    }

    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    static func buildRequest(token: String) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = 15
        return request
    }

    static func parseResponse(data: Data) throws -> UsageResponse {
        return try JSONDecoder.apiDecoder.decode(UsageResponse.self, from: data)
    }

    static func fetch() async throws -> UsageResponse {
        let token = try KeychainService.getAccessToken()
        let request = try buildRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw ServiceError.tokenExpired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.httpError(httpResponse.statusCode)
        }

        return try parseResponse(data: data)
    }
}
