import Foundation

final class CSVConverterBackend: ObservableObject {
    @Published var output: String = ""

    func convertToJSON(csv: String) {
        let lines = csv.components(separatedBy: "\n")
        guard lines.count > 1 else { return }
        let headers = lines[0].components(separatedBy: ",")

        var results: [[String: String]] = []
        for i in 1..<lines.count {
            let fields = lines[i].components(separatedBy: ",")
            if fields.count == headers.count {
                var dict: [String: String] = [:]
                for j in 0..<headers.count {
                    dict[headers[j].trimmingCharacters(in: .whitespaces)] = fields[j].trimmingCharacters(in: .whitespaces)
                }
                results.append(dict)
            }
        }

        if let data = try? JSONSerialization.data(withJSONObject: results, options: .prettyPrinted),
           let json = String(data: data, encoding: .utf8) {
            self.output = json
        }
    }
}
