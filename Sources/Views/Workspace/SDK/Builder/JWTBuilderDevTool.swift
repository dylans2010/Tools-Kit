import SwiftUI

struct JWTBuilderDevTool: DevTool {
    let id = "jwt-builder"
    let name = "JWT Builder"
    let category: DevToolCategory = .security
    let icon = "badge.plus.radiowaves.right"
    let description = "Manually construct JWT tokens (unsecured/debug)"

    func render() -> some View {
        JWTBuilderView()
    }
}

struct JWTBuilderView: View {
    @State private var header = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}"
    @State private var payload = "{\"sub\":\"1234567890\",\"name\":\"John Doe\",\"iat\":1516239022}"
    @State private var token = ""

    var body: some View {
        Form {
            Section("Header (JSON)") {
                TextEditor(text: $header)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 80)
            }
            Section("Payload (JSON)") {
                TextEditor(text: $payload)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 120)
            }
            Button("Build Token (Unsigned)") {
                build()
            }
            .frame(maxWidth: .infinity)

            if !token.isEmpty {
                Section("Result") {
                    Text(token)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func build() {
        guard let hData = header.data(using: .utf8), let pData = payload.data(using: .utf8) else { return }
        let hBase64 = hData.base64EncodedString().replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        let pBase64 = pData.base64EncodedString().replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        token = "\(hBase64).\(pBase64).SIGNATURE_STUB"
    }
}
