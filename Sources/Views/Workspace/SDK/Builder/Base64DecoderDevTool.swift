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
        Form {
            Section("Input Base64") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 120)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Output") {
                if viewModel.isError {
                    Text(viewModel.outputText)
                        .foregroundStyle(.red)
                        .font(.caption)
                } else {
                    Text(viewModel.outputText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(minHeight: 60)
                }

                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.outputText
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("decoded_base64.txt")
                        try? viewModel.outputText.write(to: fileURL, atomically: true, encoding: .utf8)
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
                .disabled(viewModel.isError)
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
        didSet {
            decode()
        }
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

        // Fix padding
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + (4 - remainder), withPad: "=", startingAt: 0)
        }

        guard let data = Data(base64Encoded: base64) else {
            outputText = "Invalid Base64 format"
            isError = true
            return
        }

        if let decodedString = String(data: data, encoding: .utf8) {
            outputText = decodedString
            isError = false
        } else {
            outputText = "Data decoded but contains non-UTF8 characters (\(data.count) bytes)"
            isError = false
        }

        if history.first?.title != inputText {
            history.insert(HistoryItem(title: inputText, detail: isError ? "Failed decode" : "Decoded successfully"), at: 0)
        }
    }
}

#Preview {
    Base64DecoderView()
}
