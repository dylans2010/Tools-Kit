import Foundation
import Appwrite

final class AppwriteClient {
    static let shared = AppwriteClient()

    private let endpoint = "https://fra.cloud.appwrite.io/v1"
    private let projectID = "69e24c32003548ff0e2e"

    let client: Client
    let account: Account

    private init() {
        client = Client()
            .setEndpoint(endpoint)
            .setProject(projectID)
        account = Account(client)
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
