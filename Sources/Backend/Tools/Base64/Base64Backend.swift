import Foundation

class Base64Backend: ObservableObject {
    @Published var inputText = ""
    @Published var outputText = ""

    func encode() {
        let data = Data(inputText.utf8)
        outputText = data.base64EncodedString()
    }

    func decode() {
        var base64 = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle Base64URL
        base64 = base64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if missing
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }

        if let data = Data(base64Encoded: base64) {
            outputText = String(data: data, encoding: .utf8) ?? "Decoded binary data (\(data.count) bytes)"
        } else {
            outputText = "Invalid Base64 string"
        }
    }

    func clear() {
        inputText = ""
        outputText = ""
    }
}
