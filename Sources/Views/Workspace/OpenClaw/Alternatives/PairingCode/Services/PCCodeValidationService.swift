import Foundation

public actor PCCodeValidationService {
    public static let shared = PCCodeValidationService()
    private init() {}

    public func validateCode(_ request: PCValidationRequest, gatewayHost: String, gatewayPort: Int) async throws -> PCValidationResponse {
        guard !gatewayHost.isEmpty && gatewayHost != "localhost" else {
            throw PCError.networkFailure("Real gateway address required")
        }

        let urlString = "http://\(gatewayHost):\(gatewayPort)\(PCConstants.validationEndpoint)"
        guard let url = URL(string: urlString) else {
            throw PCError.networkFailure("Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PCError.networkFailure("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(PCValidationResponse.self, from: data)
        case 401:
            throw PCError.codeInvalid
        case 429:
            throw PCError.rateLimited(60)
        case 423:
            throw PCError.gatewayLocked
        default:
            throw PCError.networkFailure("HTTP \(httpResponse.statusCode)")
        }
    }
}
