import Foundation

enum AppwriteClientError: LocalizedError {
    case configFileUnreadable
    case missingConfig(String)
    case emptyConfig(String)
    case invalidEndpoint(String)

    var errorDescription: String? {
        switch self {
        case .configFileUnreadable:
            return "Config.plist exists but could not be read."
        case .missingConfig(let key):
            return "Missing required Appwrite configuration value '\(key)' in Config.plist (or Info.plist fallback)."
        case .emptyConfig(let key):
            return "Appwrite configuration value '\(key)' must not be empty."
        case .invalidEndpoint(let value):
            return "Invalid Appwrite endpoint: '\(value)'."
        }
    }
}

final class AppwriteClient {
    static let shared = AppwriteClient()

    private init() {}

    private static func requiredConfigValue(forKeys keys: [String], from dictionary: [String: Any]) throws -> String {
        for key in keys {
            if let value = dictionary[key] as? String {
                let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedValue.isEmpty else {
                    throw AppwriteClientError.emptyConfig(key)
                }
                return trimmedValue
            }
        }

        throw AppwriteClientError.missingConfig(keys.first ?? "")
    }

    private static func loadConfigPlist() throws -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist") else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            throw AppwriteClientError.configFileUnreadable
        }

        let object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let dictionary = object as? [String: Any] else {
            throw AppwriteClientError.configFileUnreadable
        }

        return dictionary
    }

    private static func resolvedConfiguration(from dictionary: [String: Any]) throws -> (endpoint: String, projectID: String) {
        let endpoint = try requiredConfigValue(
            forKeys: ["APPWRITE_PUBLIC_ENDPOINT", "APPWRITE_ENDPOINT"],
            from: dictionary
        )
        let projectID = try requiredConfigValue(
            forKeys: ["APPWRITE_PROJECT_ID"],
            from: dictionary
        )
        try validateEndpoint(endpoint)
        return (endpoint, projectID)
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
        if let configDictionary = try loadConfigPlist() {
            return try resolvedConfiguration(from: configDictionary)
        }

        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        return try resolvedConfiguration(from: infoDictionary)
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
