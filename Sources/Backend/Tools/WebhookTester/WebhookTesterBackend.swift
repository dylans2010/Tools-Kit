import Foundation

class WebhookTesterBackend: ObservableObject {
    @Published var urlString = "https://webhook.site/"
    @Published var payload = "{\n  \"event\": \"test\",\n  \"status\": \"success\"\n}"
    @Published var responseText = ""
    @Published var isLoading = false
    @Published var error: String? = nil

    @MainActor
    func send() {
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload.data(using: .utf8)

        isLoading = true
        error = nil
        responseText = ""

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                isLoading = false
                if let httpResponse = response as? HTTPURLResponse {
                    let status = httpResponse.statusCode
                    let body = String(data: data, encoding: .utf8) ?? "No Body"
                    self.responseText = "Status: \(status)\n\nResponse Body:\n\(body)"
                }
            } catch {
                isLoading = false
                self.error = error.localizedDescription
            }
        }
    }
}
