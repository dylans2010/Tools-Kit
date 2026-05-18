import SwiftUI

struct JWTDecoderDevTool: DevTool {
    let id = "jwt-decoder"
    let name = "JWT Decoder"
    let category = DevToolCategory.security
    let icon = "badge.plus.radiowaves.right"
    let description = "Decode JSON Web Tokens"

    func render() -> some View {
        JWTDecoderView()
    }
}

struct JWTDecoderView: View {
    @StateObject private var viewModel = JWTDecoderViewModel()

    var body: some View {
        Form {
            Section("JWT Token") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
                    .font(.monospaced(.body)())
            }

            Section("Payload") {
                Text(viewModel.payload)
                    .font(.monospaced(.caption)())
                    .textSelection(.enabled)
            }
        }
    }
}

class JWTDecoderViewModel: ObservableObject {
    @Published var inputText = ""

    var payload: String {
        let parts = inputText.components(separatedBy: ".")
        guard parts.count >= 2 else { return "Invalid JWT" }

        let payloadPart = parts[1]
        var base64 = payloadPart
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = Int(requiredLength) - Int(length)
        if paddingLength > 0 {
            base64 += String(repeating: "=", count: paddingLength)
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            return "Failed to decode payload"
        }

        return String(data: prettyData, encoding: .utf8) ?? "Failed to decode payload"
    }
}
