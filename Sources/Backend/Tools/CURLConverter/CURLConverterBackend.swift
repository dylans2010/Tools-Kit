import Foundation

final class CURLConverterBackend: ObservableObject {
    @Published var swiftCode: String = ""

    func convert(curl: String) {
        // Enhanced regex-based parsing for cURL to Swift Code
        var url = "https://api.example.com"
        var method = "GET"
        var headers: [String: String] = [:]
        var body = ""

        // Extract URL
        if let match = curl.range(of: "'https?://[^']+'", options: .regularExpression) {
            url = String(curl[match]).replacingOccurrences(of: "'", with: "")
        } else if let match = curl.range(of: "\"https?://[^\"]+\"", options: .regularExpression) {
            url = String(curl[match]).replacingOccurrences(of: "\"", with: "")
        }

        // Extract Method
        if curl.contains("-X POST") { method = "POST" }
        else if curl.contains("-X PUT") { method = "PUT" }
        else if curl.contains("-X DELETE") { method = "DELETE" }

        // Extract Headers
        let headerPattern = #"-H\s+['"]([^'"]+)['"]"#
        let regex = try? NSRegularExpression(pattern: headerPattern)
        let matches = regex?.matches(in: curl, range: NSRange(curl.startIndex..., in: curl)) ?? []
        for match in matches {
            if let range = Range(match.range(at: 1), in: curl) {
                let header = String(curl[range])
                let parts = header.components(separatedBy: ":")
                if parts.count >= 2 {
                    headers[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
                }
            }
        }

        // Generate Swift Code
        var code = "import Foundation\n\n"
        code += "func executeRequest() {\n"
        code += "    guard let url = URL(string: \"\(url)\") else { return }\n"
        code += "    var request = URLRequest(url: url)\n"
        code += "    request.httpMethod = \"\(method)\"\n\n"

        for (key, value) in headers {
            code += "    request.addValue(\"\(value)\", forHTTPHeaderField: \"\(key)\")\n"
        }

        code += "\n"
        code += "    let task = URLSession.shared.dataTask(with: request) { data, response, error in\n"
        code += "        if let error = error {\n"
        code += "            print(\"Error: \\(error)\")\n"
        code += "            return\n"
        code += "        }\n"
        code += "        guard let data = data else { return }\n"
        code += "        print(\"Received: \\(data.count) bytes\")\n"
        code += "    }\n"
        code += "    task.resume()\n"
        code += "}"

        self.swiftCode = code
    }
}
