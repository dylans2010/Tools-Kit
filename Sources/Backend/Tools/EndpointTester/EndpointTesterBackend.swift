import Foundation

struct EndpointHeader: Identifiable, Equatable {
    let id = UUID()
    var key: String
    var value: String
}

struct EndpointResponse {
    let statusCode: Int
    let headers: [String: String]
    let body: String
    let durationMs: Int
    let size: Int
}

@MainActor
final class EndpointTesterBackend: ObservableObject {
    @Published var urlString = "https://httpbin.org/get"
    @Published var method = "GET"
    @Published var headers: [EndpointHeader] = [
        EndpointHeader(key: "Accept", value: "application/json")
    ]
    @Published var requestBody = ""
    @Published var response: EndpointResponse?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var curlCommand = ""

    let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]

    func send() async {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) else {
            errorMessage = "Invalid URL"
            return
        }

        isLoading = true
        errorMessage = ""
        response = nil
        updateCURLCommand()

        var request = URLRequest(url: url)
        request.httpMethod = method
        for header in headers where !header.key.isEmpty {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        if method != "GET" && method != "HEAD" && !requestBody.isEmpty {
            request.httpBody = requestBody.data(using: .utf8)
        }

        let start = Date()
        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)
            let httpResponse = urlResponse as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            let responseHeaders = (httpResponse?.allHeaderFields as? [String: String]) ?? [:]

            var bodyString = ""
            if let json = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                bodyString = String(data: pretty, encoding: .utf8) ?? ""
            } else {
                bodyString = String(data: data, encoding: .utf8) ?? "(binary data)"
            }

            response = EndpointResponse(
                statusCode: statusCode,
                headers: responseHeaders,
                body: bodyString,
                durationMs: durationMs,
                size: data.count
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addHeader() {
        headers.append(EndpointHeader(key: "", value: ""))
    }

    func removeHeader(at offsets: IndexSet) {
        headers.remove(atOffsets: offsets)
    }

    private func updateCURLCommand() {
        var parts = ["curl -X \(method)"]
        for header in headers where !header.key.isEmpty {
            parts.append("-H \"\(header.key): \(header.value)\"")
        }
        if method != "GET" && method != "HEAD" && !requestBody.isEmpty {
            let escaped = requestBody.replacingOccurrences(of: "\"", with: "\\\"")
            parts.append("-d \"\(escaped)\"")
        }
        parts.append("\"\(urlString)\"")
        curlCommand = parts.joined(separator: " \\\n  ")
    }
}
