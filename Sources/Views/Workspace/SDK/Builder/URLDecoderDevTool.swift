import SwiftUI

struct URLDecoderDevTool: DevTool {
    let id = "url-decoder"
    let name = "URL Decoder"
    let category = DevToolCategory.encoding
    let icon = "link.badge.plus"
    let description = "Decode percent-encoded URL strings"

    func render() -> some View {
        URLDecoderView()
    }
}

struct URLDecoderView: View {
    @StateObject private var viewModel = URLDecoderViewModel()

    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 120)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Output") {
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
                        let fileURL = tempDir.appendingPathComponent("url_decoded.txt")
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

class URLDecoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            decode()
        }
    }
    @Published var outputText = ""
    @Published var history: [HistoryItem] = []

    private func decode() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }

        outputText = inputText.removingPercentEncoding ?? ""

        if history.first?.title != inputText {
            history.insert(HistoryItem(title: inputText, detail: "URL Decoded"), at: 0)
        }
    }
}

#Preview {
    URLDecoderView()
}
