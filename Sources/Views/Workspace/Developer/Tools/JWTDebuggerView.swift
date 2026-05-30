import SwiftUI

struct JWTDebuggerView: View {
    @State private var jwtInput = ""
    @State private var headerJSON = ""
    @State private var payloadJSON = ""
    @State private var signature = ""
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Encoded JWT").font(.headline)
                    TextEditor(text: $jwtInput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 120)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }

                Button("Decode JWT") {
                    decodeJWT()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if !headerJSON.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Header").font(.headline).foregroundStyle(.red)
                        decodedBox(text: headerJSON)

                        Text("Payload").font(.headline).foregroundStyle(.purple)
                        decodedBox(text: payloadJSON)

                        Text("Signature").font(.headline).foregroundStyle(.blue)
                        Text(signature)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("JWT Debugger")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func decodedBox(text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
    }

    private func decodeJWT() {
        errorMessage = nil
        headerJSON = ""
        payloadJSON = ""
        signature = ""

        let parts = jwtInput.components(separatedBy: ".")
        guard parts.count == 3 else {
            errorMessage = "Invalid JWT: Must have 3 parts separated by dots"
            return
        }

        headerJSON = decodePart(parts[0]) ?? "Invalid Header"
        payloadJSON = decodePart(parts[1]) ?? "Invalid Payload"
        signature = parts[2]
    }

    private func decodePart(_ part: String) -> String? {
        var base64 = part
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = Int(requiredLength) - base64.count
        if paddingLength > 0 {
            let padding = String(repeating: "=", count: paddingLength)
            base64 += padding
        }

        guard let data = Data(base64Encoded: base64) else { return nil }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            return String(data: prettyData, encoding: .utf8)
        } catch {
            return String(data: data, encoding: .utf8)
        }
    }
}
