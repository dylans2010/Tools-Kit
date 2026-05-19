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

    var body: some View {
        Form {
            Section("Input JWT") {
                TextEditor(text: $viewModel.input)
                    .frame(height: 100)
                    .font(.system(.caption2, design: .monospaced))
            }

            if !viewModel.header.isEmpty {
                Section("Header") {
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
                }

                Section("Payload") {
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

                Section("Signature") {
                    Text(viewModel.signature)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
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

    private func decode() {
        let segments = input.components(separatedBy: ".")
        guard segments.count == 3 else {
            header = ""
            payload = ""
            signature = ""
            return
        }

        header = decodeSegment(segments[0])
        payload = decodeSegment(segments[1])
        signature = segments[2]
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
