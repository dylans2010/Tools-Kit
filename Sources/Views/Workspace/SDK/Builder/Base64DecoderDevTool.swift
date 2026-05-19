import SwiftUI

struct Base64DecoderDevTool: DevTool {
    let id = "base64-decoder"
    let name = "Base64 Decoder"
    let category = DevToolCategory.encoding
    let icon = "command.square"
    let description = "Decode Base64 strings back to original format"

    func render() -> some View {
        Base64DecoderView()
    }
}

struct Base64DecoderView: View {
    @StateObject private var viewModel = Base64DecoderViewModel()

    var body: some View {
        List {
            Section("Input Base64") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 140)
                        .font(.system(.subheadline, design: .monospaced))

                    if !viewModel.inputText.isEmpty {
                        Button { viewModel.inputText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }

                HStack {
                    Button("Paste") {
                        if let s = UIPasteboard.general.string { viewModel.inputText = s }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()

                    if viewModel.isError {
                        Label("Invalid Base64", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }

            Section("Decoded Result") {
                if viewModel.isError {
                    Text(viewModel.outputText)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.outputText)
                            .font(.system(.subheadline, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)

                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = viewModel.outputText
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                viewModel.shareOutput()
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("History")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        viewModel.history.removeAll()
                    }
                    .font(.caption)
                    .disabled(viewModel.history.isEmpty)
                }

                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock", description: Text("Your activity will appear here."))
                        .frame(height: 200)
                } else {
                    List {
                        ForEach(viewModel.history) { item in
                            Button {
                                viewModel.inputText = item.title
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.subheadline.bold())
                                    Text(item.detail)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .foregroundStyle(.secondary)
                                    Text(item.timestamp, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 300)
                }
            } header: {
                Text("History")
            }
        }
    }
}

class Base64DecoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet { decode() }
    }
    @Published var outputText = ""
    @Published var isError = false
    @Published var history: [HistoryItem] = []

    private func decode() {
        guard !inputText.isEmpty else {
            outputText = ""
            isError = false
            return
        }

        var base64 = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        base64 = base64.replacingOccurrences(of: "-", with: "+")
                       .replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + (4 - remainder), withPad: "=", startingAt: 0)
        }

        guard let data = Data(base64Encoded: base64) else {
            outputText = "Malformed Base64 string. Check for invalid characters or length."
            isError = true
            return
        }

        if let decodedString = String(data: data, encoding: .utf8) {
            outputText = decodedString
            isError = false
        } else {
            // Hex dump for binary
            outputText = "Binary Data (\(data.count) bytes):\n" + data.map { String(format: "%02hhX", $0) }.joined(separator: " ")
            isError = false
        }

        if history.first?.title != inputText {
            history.insert(HistoryItem(title: inputText, detail: isError ? "Failed" : "Success"), at: 0)
            if history.count > 20 { history.removeLast() }
        }
    }

    func shareOutput() {
        let av = UIActivityViewController(activityItems: [outputText], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

#Preview {
    Base64DecoderView()
}
