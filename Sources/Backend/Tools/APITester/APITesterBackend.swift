import Foundation

struct HTTPHeader: Identifiable, Equatable, Sendable {
    let id = UUID()
    var key: String
    var value: String
}

class APITesterBackend: ObservableObject {
    @Published var url = "https://jsonplaceholder.typicode.com/posts"
    @Published var method = "POST"
    @Published var headers: [HTTPHeader] = [
        HTTPHeader(key: "Content-Type", value: "application/json")
    ]
    @Published var requestBody = "{\n  \"title\": \"foo\",\n  \"body\": \"bar\",\n  \"userId\": 1\n}"
    @Published var responseBody = ""
    @Published var responseStatus = 0
    @Published var isLoading = false
    @Published var responseHeaders: [String: String] = [:]

    let methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD"]

    func sendRequest() {
        guard let url = URL(string: url) else {
            self.responseBody = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Add custom headers
        for header in headers {
            if !header.key.isEmpty {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }

        if method != "GET" && method != "HEAD" && !requestBody.isEmpty {
            request.httpBody = requestBody.data(using: .utf8)
        }

        isLoading = true
        responseBody = ""
        responseStatus = 0
        responseHeaders = [:]

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.responseBody = "Error: \(error.localizedDescription)"
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    self.responseStatus = httpResponse.statusCode
                    self.responseHeaders = httpResponse.allHeaderFields as? [String: String] ?? [:]
                }

                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]) {
                        self.responseBody = String(data: prettyData, encoding: .utf8) ?? ""
                    } else {
                        self.responseBody = String(data: data, encoding: .utf8) ?? ""
                    }
                }
            }
        }.resume()
    }

    func addHeader() {
        headers.append(HTTPHeader(key: "", value: ""))
    }

    func removeHeader(at offsets: IndexSet) {
        headers.remove(atOffsets: offsets)
    }
}
