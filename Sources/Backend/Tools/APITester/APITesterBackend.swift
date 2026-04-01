import Foundation

class APITesterBackend: ObservableObject {
    @Published var url = "https://jsonplaceholder.typicode.com/posts"
    @Published var method = "POST"
    @Published var requestBody = "{\n  \"title\": \"foo\",\n  \"body\": \"bar\",\n  \"userId\": 1\n}"
    @Published var responseBody = ""
    @Published var responseStatus = 0
    @Published var isLoading = false

    let methods = ["GET", "POST", "PUT", "DELETE"]

    func sendRequest() {
        guard let url = URL(string: url) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = method

        if method != "GET" && !requestBody.isEmpty {
            request.httpBody = requestBody.data(using: .utf8)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        isLoading = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.responseBody = "Error: \(error.localizedDescription)"
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    self.responseStatus = httpResponse.statusCode
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
}
