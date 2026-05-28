import SwiftUI

struct Base64EncoderDevTool: DevTool {
    let id = "base64-encoder"
    let name = "Base64 Encoder"
    let category = DevToolCategory.encoding
    let icon = "text.and.command.macwindow"
    let description = "Encode text or binary data to Base64"

    func render() -> some View {
        Base64EncoderView()
    }
}

struct Base64EncoderView: View {
    @StateObject private var viewModel = Base64EncoderViewModel()

    var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 120)
                    .font(.system(.body, design: .monospaced))
            }

            Section(header: Text("Configuration")) {
                Toggle("URL Safe Encoding", isOn: $viewModel.isURLSafe)
                Picker("Encoding", selection: $viewModel.encoding) {
                    Text("UTF-8").tag(String.Encoding.utf8)
                    Text("UTF-16").tag(String.Encoding.utf16)
                    Text("ASCII").tag(String.Encoding.ascii)
                }
            }

            Section(header: Text("Output")) {
                Text(viewModel.outputText)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(minHeight: 60)

                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.outputText
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("encoded_base64.txt")
                        try? viewModel.outputText.write(to: fileURL, atomically: true, encoding: .utf8)
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
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

class Base64EncoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            encode()
        }
    }
    @Published var outputText = ""
    @Published var isURLSafe = false {
        didSet { encode() }
    }
    @Published var encoding = String.Encoding.utf8 {
        didSet { encode() }
    }
    @Published var history: [HistoryItem] = []

    private func encode() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }

        guard let data = inputText.data(using: encoding) else {
            outputText = "Invalid encoding"
            return
        }

        var base64 = data.base64EncodedString()
        if isURLSafe {
            base64 = base64.replacingOccurrences(of: "+", with: "-")
                           .replacingOccurrences(of: "/", with: "_")
                           .replacingOccurrences(of: "=", with: "")
        }

        outputText = base64

        // Update history periodically or on specific triggers to avoid spam
        if history.first?.title != inputText {
             history.insert(HistoryItem(title: inputText, detail: "Encoded to \(encoding)"), at: 0)
        }
    }
}

#Preview {
    Base64EncoderView()
}
