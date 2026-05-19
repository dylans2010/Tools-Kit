import SwiftUI

struct JWTDecoderDevTool: DevTool {
    let id = "jwt-decoder"
    let name = "JWT Decoder"
    let category = DevToolCategory.security
    let icon = "key.horizontal"
    let description = "Decode and inspect JSON Web Tokens"

    func render() -> some View {
        JWTDecoderDevToolView()
    }
}

struct JWTDecoderDevToolView: View {
    @StateObject private var viewModel = JWTDecoderViewModel()
    @State private var showingDetails = true

    var body: some View {
        List {
            Section("Token Source") {
                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topTrailing) {
                        TextEditor(text: $viewModel.input)
                            .frame(height: 140)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(4)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)

                        if !viewModel.input.isEmpty {
                            Button { viewModel.input = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                            .padding(8)
                        }
                    }

                    HStack {
                        Button("Paste from Clipboard") {
                            if let s = UIPasteboard.general.string { viewModel.input = s }
                        }
                        .buttonStyle(.bordered).controlSize(.small)

                        Spacer()

                        if viewModel.isExpired {
                            Label("EXPIRED", systemImage: "clock.badge.exclamationmark")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if !viewModel.header.isEmpty {
                Section("Validation Status") {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title2)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Structurally Valid").font(.subheadline.bold())
                            Text("Algorithm: \(viewModel.algorithm)").font(.system(size: 9)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Claims & Payload") {
                    ForEach(viewModel.claims, id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(key).font(.system(size: 8, weight: .black)).foregroundStyle(.blue).textCase(.uppercase)
                            Text(value).font(.system(size: 11, design: .monospaced)).foregroundStyle(.primary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Full Header") {
                    JSONPreviewBox(text: viewModel.header)
                }

                Section("Full Body") {
                    JSONPreviewBox(text: viewModel.payload)
                }

                Section("Raw Signature") {
                    Text(viewModel.signature)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(6)
                }
            }
        }
        .navigationTitle("JWT Lab")
    }
}

struct JSONPreviewBox: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .frame(maxHeight: 200)
    }
}

class JWTDecoderViewModel: ObservableObject {
    @Published var input = "" {
        didSet { decode() }
    }
    @Published var header = ""
    @Published var payload = ""
    @Published var signature = ""
    @Published var algorithm = "Unknown"
    @Published var isExpired = false
    @Published var claims: [(key: String, value: String)] = []

    private func decode() {
        let segments = input.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".")
        guard segments.count == 3 else {
            header = ""; payload = ""; signature = ""; claims = []
            return
        }

        header = decodeSegment(segments[0])
        payload = decodeSegment(segments[1])
        signature = segments[2]

        extractClaims()
    }

    private func decodeSegment(_ segment: String) -> String {
        var base64 = segment.replacingOccurrences(of: "-", with: "+")
                            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + (4 - remainder), withPad: "=", startingAt: 0)
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return ""
        }
        return prettyString
    }

    private func extractClaims() {
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        claims = json.map { (key: $0.key, value: "\($0.value)") }.sorted { $0.key < $1.key }

        if let algData = header.data(using: .utf8),
           let algJson = try? JSONSerialization.jsonObject(with: algData) as? [String: Any] {
            algorithm = algJson["alg"] as? String ?? "Unknown"
        }

        if let exp = json["exp"] as? Double {
            isExpired = Date().timeIntervalSince1970 > exp
        }
    }
}

#Preview {
    JWTDecoderDevToolView()
}
