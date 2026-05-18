import SwiftUI

struct JWTDecoderTool: DevTool {
    let id = UUID()
    let name = "JWT Decoder"
    let category: DevToolCategory = .security
    let icon = "lock.doc"
    let description = "Decode and inspect JWT tokens"
    func render() -> some View { JWTDecoderDevToolView() }
}

struct JWTDecoderDevToolView: View {
    @State private var token = ""
    @State private var header: [(String, String)] = []
    @State private var payload: [(String, String)] = []
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section("JWT Token") {
                TextEditor(text: $token)
                    .frame(minHeight: 80)
                    .font(.system(.caption, design: .monospaced))
            }
            Section {
                Button("Decode") { decode() }
                    .disabled(token.isEmpty)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if !header.isEmpty {
                Section("Header") {
                    ForEach(header, id: \.0) { key, value in
                        LabeledContent(key, value: value).font(.system(.caption, design: .monospaced))
                    }
                }
            }
            if !payload.isEmpty {
                Section("Payload") {
                    ForEach(payload, id: \.0) { key, value in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(key).font(.caption.bold())
                            Text(value).font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary).textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .navigationTitle("JWT Decoder")
    }

    private func decode() {
        errorMsg = nil; header.removeAll(); payload.removeAll()
        let parts = token.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".")
        guard parts.count >= 2 else { errorMsg = "Invalid JWT format (expected 3 parts separated by dots)"; return }
        if let h = decodeBase64(String(parts[0])) { header = h }
        if let p = decodeBase64(String(parts[1])) {
            payload = p.map { key, value in
                if (key == "exp" || key == "iat" || key == "nbf"), let ts = Double(value) {
                    let date = Date(timeIntervalSince1970: ts)
                    let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .medium
                    return (key, "\(value) (\(f.string(from: date)))")
                }
                return (key, value)
            }
        }
    }

    private func decodeBase64(_ str: String) -> [(String, String)]? {
        var base64 = str.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json.map { ($0.key, "\($0.value)") }.sorted { $0.0 < $1.0 }
    }
}
