import Foundation

class Base64Backend: ObservableObject {
    @Published var inputText = ""
    @Published var outputText = ""

    func encode() {
        let data = Data(inputText.utf8)
        outputText = data.base64EncodedString()
    }

    func decode() {
        if let data = Data(base64Encoded: inputText) {
            outputText = String(data: data, encoding: .utf8) ?? "Invalid UTF-8 data"
        } else {
            outputText = "Invalid Base64 string"
        }
    }
}
