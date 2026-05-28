import SwiftUI

struct URLEncoderDevTool: DevTool {
    let id = "url-encoder"
    let name = "URL Encoder"
    let category = DevToolCategory.encoding
    let icon = "link"
    let description = "Percent-encode strings for use in URLs"

    func render() -> some View {
        URLEncoderView()
    }
}

struct URLEncoderView: View {
    @StateObject private var viewModel = URLEncoderViewModel()

    var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 120)
                    .font(.system(.body, design: .monospaced))
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
                        let fileURL = tempDir.appendingPathComponent("url_encoded.txt")
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

class URLEncoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            encode()
        }
    }
    @Published var outputText = ""
    @Published var history: [HistoryItem] = []

    private func encode() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }

        outputText = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if history.first?.title != inputText {
            history.insert(HistoryItem(title: inputText, detail: "URL Encoded"), at: 0)
        }
    }
}

#Preview {
    URLEncoderView()
}
