import Foundation

class JSONFormatterBackend: ObservableObject {
    @Published var inputText = ""
    @Published var outputText = ""
    @Published var isValid = true

    func format() {
        guard !inputText.isEmpty else {
            outputText = ""
            isValid = true
            return
        }

        guard let data = inputText.data(using: .utf8) else {
            isValid = false
            outputText = "Error: Invalid character encoding"
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let formattedData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            outputText = String(data: formattedData, encoding: .utf8) ?? ""
            isValid = true
        } catch {
            isValid = false
            outputText = "Error: \(error.localizedDescription)"
        }
    }
}
