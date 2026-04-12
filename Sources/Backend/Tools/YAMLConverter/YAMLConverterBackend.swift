import Foundation

final class YAMLConverterBackend: ObservableObject {
    @Published var output: String = ""
    @Published var error: String?

    func convertToJSON(yaml: String) {
        // Basic manual YAML-to-JSON logic for demonstration/MVP
        // In a production environment, we'd use a robust library like Yams.
        let lines = yaml.components(separatedBy: "\n")
        var result: [String: Any] = [:]

        for line in lines {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)

                if !key.isEmpty {
                    if let intVal = Int(value) { result[key] = intVal }
                    else if let boolVal = Bool(value) { result[key] = boolVal }
                    else { result[key] = value }
                }
            }
        }

        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            self.output = json
        } else {
            self.error = "Failed to convert YAML"
        }
    }
}
