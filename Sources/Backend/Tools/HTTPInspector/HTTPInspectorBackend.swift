import Foundation

class HTTPInspectorBackend: ObservableObject {
    @Published var url = ""
    @Published var responseHeaders: [String: String] = [:]
    @Published var isLoading = false
    @Published var error = ""

    func inspect() {
        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let urlObj = URL(string: trimmedUrl) else {
            error = "Invalid URL"
            return
        }

        isLoading = true
        error = ""
        responseHeaders = [:]

        var request = URLRequest(url: urlObj)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, urlError in
            DispatchQueue.main.async {
                self.isLoading = false
                if let urlError = urlError {
                    self.error = urlError.localizedDescription
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    self.responseHeaders = httpResponse.allHeaderFields as? [String: String] ?? [:]
                } else {
                    self.error = "Not an HTTP response"
                }
            }
        }.resume()
    }
}
