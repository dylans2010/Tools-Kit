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
        List {
            Section("Input URL/Text") {
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

                    Text("\(viewModel.inputText.count) chars").font(.caption2).foregroundStyle(.secondary)
                }
            }

            Section("Encoding Mode") {
                Picker("Allowed Characters", selection: $viewModel.allowedSet) {
                    Text("Query").tag(URLEncodingSet.query)
                    Text("Path").tag(URLEncodingSet.path)
                    Text("Host").tag(URLEncodingSet.host)
                    Text("Fragment").tag(URLEncodingSet.fragment)
                }
                .pickerStyle(.menu)
            }

            Section("Percent Encoded Output") {
                Text(viewModel.outputText)
                    .font(.system(.subheadline, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                    .padding(8)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.1), lineWidth: 1))

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = viewModel.outputText
                    } label: {
                        Label("Copy Result", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        viewModel.shareResult()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
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

enum URLEncodingSet {
    case query, path, host, fragment

    var characters: CharacterSet {
        switch self {
        case .query: return .urlQueryAllowed
        case .path: return .urlPathAllowed
        case .host: return .urlHostAllowed
        case .fragment: return .urlFragmentAllowed
        }
    }
}

class URLEncoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet { encode() }
    }
    @Published var allowedSet = URLEncodingSet.query {
        didSet { encode() }
    }
    @Published var outputText = ""
    @Published var history: [HistoryItem] = []

    private func encode() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }

        outputText = inputText.addingPercentEncoding(withAllowedCharacters: allowedSet.characters) ?? ""

        if history.first?.title != inputText {
            history.insert(HistoryItem(title: inputText, detail: "URL Encoded"), at: 0)
            if history.count > 20 { history.removeLast() }
        }
    }

    func shareResult() {
        let av = UIActivityViewController(activityItems: [outputText], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

#Preview {
    URLEncoderView()
}
