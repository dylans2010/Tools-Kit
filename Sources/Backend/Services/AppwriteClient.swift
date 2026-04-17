import Foundation

enum AppwriteClientError: LocalizedError {
    case missingConfig(String)
    case emptyConfig(String)
    case invalidEndpoint(String)

    var errorDescription: String? {
        switch self {
        case .missingConfig(let key):
            return "Missing required Appwrite configuration value '\(key)' in Info.plist."
        case .emptyConfig(let key):
            return "Appwrite configuration value '\(key)' in Info.plist must not be empty."
        case .invalidEndpoint(let value):
            return "Invalid APPWRITE_ENDPOINT in Info.plist: '\(value)'."
        }
    }
}

final class AppwriteClient {
    static let shared = AppwriteClient()

    private init() {}

    private static func requiredConfigValue(forKey key: String) throws -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            throw AppwriteClientError.missingConfig(key)
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            throw AppwriteClientError.emptyConfig(key)
        }

        return trimmedValue
    }

    private static func validateEndpoint(_ endpoint: String) throws {
        guard let url = URL(string: endpoint),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            throw AppwriteClientError.invalidEndpoint(endpoint)
        }
    }

    private static func resolvedConfiguration() throws -> (endpoint: String, projectID: String) {
        let endpoint = try requiredConfigValue(forKey: "APPWRITE_ENDPOINT")
        let projectID = try requiredConfigValue(forKey: "APPWRITE_PROJECT_ID")
        try validateEndpoint(endpoint)
        return (endpoint, projectID)
    }

    // Uses Appwrite endpoint health check to validate backend reachability.
    func ping() async throws {
        let config = try Self.resolvedConfiguration()

        guard let url = URL(string: "\(config.endpoint)/health") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(config.projectID, forHTTPHeaderField: "X-Appwrite-Project")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
