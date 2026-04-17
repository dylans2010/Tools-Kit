import Foundation
import Appwrite

final class AppwriteClient {
    static let shared = AppwriteClient()

    private let endpoint: String
    private let projectID: String

    let client: Client
    let account: Account

    private init() {
        endpoint = Self.requiredConfigValue(forKey: "APPWRITE_ENDPOINT")
        projectID = Self.requiredConfigValue(forKey: "APPWRITE_PROJECT_ID")
        Self.validateEndpoint(endpoint)

        client = Client()
            .setEndpoint(endpoint)
            .setProject(projectID)
        account = Account(client)
    }

    private static func requiredConfigValue(forKey key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("Missing required Appwrite configuration value '\(key)' in Info.plist.")
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            fatalError("Appwrite configuration value '\(key)' in Info.plist must not be empty.")
        }

        return trimmedValue
    }

    private static func validateEndpoint(_ endpoint: String) {
        guard let url = URL(string: endpoint),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            fatalError("Invalid Appwrite endpoint '\(endpoint)' for key 'APPWRITE_ENDPOINT' in Info.plist. Endpoint must include a URL scheme (https/http) and host.")
        }
    }

    // Uses Appwrite endpoint health check to validate backend reachability.
    func ping() async throws {
        guard let url = URL(string: "\(endpoint)/health") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(projectID, forHTTPHeaderField: "X-Appwrite-Project")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
