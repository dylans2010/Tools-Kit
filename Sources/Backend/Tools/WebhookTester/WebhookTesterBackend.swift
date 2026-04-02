import Foundation

class WebhookTesterBackend: ObservableObject {
    @Published var urlString = "https://webhook.site/"
    @Published var payload = "{\n  \"event\": \"test\",\n  \"status\": \"success\"\n}"
    @Published var responseText = ""
    @Published var isLoading = false
    @Published var error: String? = nil

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

        URLSession.shared.dataTask(with: request) { data, response, urlError in
            DispatchQueue.main.async {
                self.isLoading = false
                if let urlError = urlError {
                    self.error = urlError.localizedDescription
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    let status = httpResponse.statusCode
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"
                    self.responseText = "Status: \(status)\n\nResponse Body:\n\(body)"
                }
            }
        }.resume()
    }
}
