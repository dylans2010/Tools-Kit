import SwiftUI

struct RegexTesterDevTool: DevTool {
    let id = "regex-tester"
    let name = "Regex Tester"
    let category = DevToolCategory.utilities
    let icon = "asterisk"
    let description = "Test Regular Expressions"

    func render() -> some View {
        RegexTesterView()
    }
}

struct RegexTesterView: View {
    @StateObject private var viewModel = RegexTesterViewModel()

    var body: some View {
        Form {
            Section("Pattern") {
                TextField("^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$", text: $viewModel.pattern)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.monospaced(.body)())
            }

            Section("Input Text") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
            }

            Section("Matches") {
                if viewModel.matches.isEmpty {
                    Text("No matches found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.matches, id: \.self) { match in
                        Text(match)
                            .font(.monospaced(.caption)())
                            .padding(4)
                            .background(Color.green.opacity(0.2))
                    }
                }
            }
        }
    }
}

class RegexTesterViewModel: ObservableObject {
    @Published var pattern = "" { didSet { test() } }
    @Published var inputText = "" { didSet { test() } }
    @Published var matches: [String] = []

    private func test() {
        guard !pattern.isEmpty, !inputText.isEmpty else {
            matches = []
            return
        }

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = inputText as NSString
            let results = regex.matches(in: inputText, range: NSRange(location: 0, length: nsString.length))
            matches = results.map { nsString.substring(with: $0.range) }
        } catch {
            matches = []
        }
    }
}
