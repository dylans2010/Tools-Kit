import SwiftUI

struct JWTDecoderDevTool: DevTool {
    let id = "jwt-decoder"
    let name = "JWT Decoder"
    let category = DevToolCategory.security
    let icon = "key.horizontal"
    let description = "Decode, inspect, and validate JSON Web Tokens"

    func render() -> some View {
        JWTDecoderDevToolView()
    }
}

struct JWTDecoderDevToolView: View {
    @StateObject private var viewModel = JWTDecoderViewModel()

    var body: some View {
        Form {
            Section(header: Text("Input JWT")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 100)
                    .font(.system(.caption2, design: .monospaced))
                HStack {
                    Button("Paste") {
                        if let text = UIPasteboard.general.string { viewModel.input = text }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                    Button("Clear") { viewModel.input = "" }
                        .buttonStyle(.bordered).controlSize(.small)
                    Button("Sample") {
                        viewModel.input = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE5MTYyMzkwMjIsInJvbGUiOiJhZG1pbiJ9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }

            if !viewModel.header.isEmpty {
                Section {
                    HStack {
                        Image(systemName: viewModel.isValid ? "checkmark.seal.fill" : "xmark.circle.fill")
                            .foregroundStyle(viewModel.isValid ? .green : .red)
                        Text(viewModel.isValid ? "Valid JWT structure" : "Invalid JWT")
                            .font(.caption)
                        Spacer()
                        Text("\(viewModel.segmentCount) segments")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Validation")
                }

                Section(header: Text("Header")) {
                    ScrollView {
                        Text(viewModel.header)
                            .font(.system(.caption2, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(8)
                    .frame(height: 100)

                    if let alg = viewModel.algorithm {
                        LabeledContent("Algorithm", value: alg)
                    }
                    if let typ = viewModel.tokenType {
                        LabeledContent("Type", value: typ)
                    }
                }

                Section(header: Text("Payload")) {
                    ScrollView {
                        Text(viewModel.payload)
                            .font(.system(.caption2, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(8)
                    .frame(height: 200)
                }

                Section(header: Text("Claims Analysis")) {
                    if let sub = viewModel.subject {
                        LabeledContent("Subject (sub)", value: sub)
                    }
                    if let iss = viewModel.issuer {
                        LabeledContent("Issuer (iss)", value: iss)
                    }
                    if let aud = viewModel.audience {
                        LabeledContent("Audience (aud)", value: aud)
                    }
                    if let iat = viewModel.issuedAt {
                        LabeledContent("Issued At (iat)", value: iat)
                    }
                    if let exp = viewModel.expiration {
                        HStack {
                            Text("Expiration (exp)")
                            Spacer()
                            Text(exp)
                                .font(.caption)
                            Image(systemName: viewModel.isExpired ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(viewModel.isExpired ? .red : .green)
                                .font(.caption)
                        }
                    }
                    if let nbf = viewModel.notBefore {
                        LabeledContent("Not Before (nbf)", value: nbf)
                    }
                }

                Section(header: Text("Signature")) {
                    Text(viewModel.signature)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Button {
                        UIPasteboard.general.string = viewModel.signature
                    } label: {
                        Label("Copy Signature", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }
        }
    }
}

class JWTDecoderViewModel: ObservableObject {
    @Published var input = "" {
        didSet { decode() }
    }
    @Published var header = ""
    @Published var payload = ""
    @Published var signature = ""
    @Published var isValid = false
    @Published var segmentCount = 0
    @Published var algorithm: String?
    @Published var tokenType: String?
    @Published var subject: String?
    @Published var issuer: String?
    @Published var audience: String?
    @Published var issuedAt: String?
    @Published var expiration: String?
    @Published var notBefore: String?
    @Published var isExpired = false

    private func decode() {
        let segments = input.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".")
        segmentCount = segments.count
        isValid = segments.count == 3

        guard segments.count == 3 else {
            header = ""; payload = ""; signature = ""
            algorithm = nil; tokenType = nil; subject = nil
            issuer = nil; audience = nil; issuedAt = nil
            expiration = nil; notBefore = nil; isExpired = false
            return
        }

        header = decodeSegment(segments[0])
        payload = decodeSegment(segments[1])
        signature = segments[2]

        analyzeHeader(segments[0])
        analyzeClaims(segments[1])
    }

    private func analyzeHeader(_ segment: String) {
        guard let data = decodeBase64Data(segment),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            algorithm = nil; tokenType = nil
            return
        }
        algorithm = json["alg"] as? String
        tokenType = json["typ"] as? String
    }

    private func analyzeClaims(_ segment: String) {
        guard let data = decodeBase64Data(segment),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            subject = nil; issuer = nil; audience = nil
            issuedAt = nil; expiration = nil; notBefore = nil
            isExpired = false
            return
        }

        subject = json["sub"] as? String
        issuer = json["iss"] as? String
        if let aud = json["aud"] {
            if let str = aud as? String { audience = str }
            else if let arr = aud as? [String] { audience = arr.joined(separator: ", ") }
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        if let iat = json["iat"] as? TimeInterval {
            issuedAt = formatter.string(from: Date(timeIntervalSince1970: iat))
        }
        if let exp = json["exp"] as? TimeInterval {
            let expDate = Date(timeIntervalSince1970: exp)
            expiration = formatter.string(from: expDate)
            isExpired = expDate < Date()
        }
        if let nbf = json["nbf"] as? TimeInterval {
            notBefore = formatter.string(from: Date(timeIntervalSince1970: nbf))
        }
    }

    private func decodeBase64Data(_ segment: String) -> Data? {
        var base64 = segment.replacingOccurrences(of: "-", with: "+")
                            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + (4 - remainder), withPad: "=", startingAt: 0)
        }
        return Data(base64Encoded: base64)
    }

    private func decodeSegment(_ segment: String) -> String {
        guard let data = decodeBase64Data(segment),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return "Invalid Segment"
        }
        return prettyString
    }
}

#Preview {
    JWTDecoderDevToolView()
}
