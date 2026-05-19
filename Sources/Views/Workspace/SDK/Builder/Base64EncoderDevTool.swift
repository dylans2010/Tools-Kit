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
        List {
            Section("Input Text") {
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

            Section("Options") {
                Toggle("URL Safe", isOn: $viewModel.isURLSafe)
                Toggle("Omit Padding (=)", isOn: $viewModel.omitPadding)
                Picker("Encoding", selection: $viewModel.encoding) {
                    Text("UTF-8").tag(String.Encoding.utf8)
                    Text("UTF-16").tag(String.Encoding.utf16)
                    Text("ASCII").tag(String.Encoding.ascii)
                }
            }

            Section("Base64 Output") {
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

class Base64EncoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet { encode() }
    }
    @Published var outputText = ""
    @Published var isURLSafe = false {
        didSet { encode() }
    }
    @Published var omitPadding = false {
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
            outputText = "Error: Incompatible Encoding"
            return
        }

        var base64 = data.base64EncodedString()

        if isURLSafe {
            base64 = base64.replacingOccurrences(of: "+", with: "-")
                           .replacingOccurrences(of: "/", with: "_")
            if omitPadding {
                base64 = base64.replacingOccurrences(of: "=", with: "")
            }
        } else if omitPadding {
            base64 = base64.replacingOccurrences(of: "=", with: "")
        }

        outputText = base64

        if history.first?.title != inputText {
            let item = HistoryItem(title: inputText, detail: "Base64 | \(encoding.description)")
            history.insert(item, at: 0)
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

extension String.Encoding: CustomStringDescription {
    public var description: String {
        switch self {
        case .utf8: return "UTF-8"
        case .utf16: return "UTF-16"
        case .ascii: return "ASCII"
        default: return "Other"
        }
    }
}

protocol CustomStringDescription {
    var description: String { get }
}

#Preview {
    Base64EncoderView()
}
