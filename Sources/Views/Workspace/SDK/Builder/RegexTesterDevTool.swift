import SwiftUI

struct RegexTesterDevTool: DevTool {
    let id = "regex-tester"
    let name = "Regex Tester"
    let category = DevToolCategory.utilities
    let icon = "asterisk"
    let description = "Test regular expressions against strings"

    func render() -> some View {
        RegexTesterDevToolView()
    }
}

struct RegexTesterDevToolView: View {
    @StateObject private var viewModel = RegexTesterViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Regex Tester",
                description: "Validate and debug regular expressions with live highlighting of matches.",
                icon: "asterisk"
            )
            .padding()

            Form {
                Section("Regex Pattern") {
                    TextField("^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$", text: $viewModel.pattern)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.system(.body, design: .monospaced))
                }

                Section("Input Text") {
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 100)
                        .font(.system(.body, design: .monospaced))
                }

                Section("Matches: \(viewModel.matches.count)") {
                    if !viewModel.isValid {
                        Text("Invalid Regex Pattern").foregroundStyle(.red).font(.caption)
                    } else if viewModel.matches.isEmpty {
                        Text("No matches found").foregroundStyle(.secondary).font(.caption)
                    } else {
                        ForEach(viewModel.matches, id: \.self) { match in
                            Text(match)
                                .font(.system(.caption, design: .monospaced))
                                .padding(4)
                                .background(Color.yellow.opacity(0.3))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
    }
}

class RegexTesterViewModel: ObservableObject {
    @Published var pattern = "[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}" {
        didSet { evaluate() }
    }
    @Published var inputText = "Contact jules@example.com or support@toolskit.io" {
        didSet { evaluate() }
    }
    @Published var matches: [String] = []
    @Published var isValid = true

    private func evaluate() {
        guard !pattern.isEmpty else {
            matches = []
            isValid = true
            return
        }

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(inputText.startIndex..<inputText.endIndex, in: inputText)
            let nsMatches = regex.matches(in: inputText, options: [], range: range)

            matches = nsMatches.compactMap { result in
                guard let range = Range(result.range, in: inputText) else { return nil }
                return String(inputText[range])
            }
            isValid = true
        } catch {
            isValid = false
            matches = []
        }
    }
}
