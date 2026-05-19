import SwiftUI

struct RegexTesterDevTool: DevTool {
    let id = "regex-tester"
    let name = "Regex Tester"
    let category = DevToolCategory.utilities
    let icon = "asterisk"
    let description = "Test regular expressions with flags, groups, and common patterns"

    func render() -> some View {
        RegexTesterDevToolView()
    }
}

struct RegexTesterDevToolView: View {
    @StateObject private var viewModel = RegexTesterViewModel()

    var body: some View {
        Form {
            Section("Regex Pattern") {
                TextField("^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$", text: $viewModel.pattern)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(.body, design: .monospaced))

                HStack(spacing: 12) {
                    Toggle("i", isOn: $viewModel.caseInsensitive)
                    Toggle("m", isOn: $viewModel.multiline)
                    Toggle("s", isOn: $viewModel.dotMatchesNewline)
                }
                .font(.system(.caption, design: .monospaced))
                .toggleStyle(.button)
            }

            Section("Input Text") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
                    .font(.system(.body, design: .monospaced))

                HStack {
                    Button("Paste") {
                        if let text = UIPasteboard.general.string {
                            viewModel.inputText = text
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Button("Clear") { viewModel.inputText = "" }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            Section("Matches (\(viewModel.matches.count))") {
                if !viewModel.isValid {
                    Label("Invalid Regex Pattern", systemImage: "xmark.circle")
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if viewModel.matches.isEmpty {
                    Text("No matches found").foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(Array(viewModel.matches.enumerated()), id: \.offset) { index, match in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Match \(index + 1)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.blue)
                                Spacer()
                                Text("[\(match.range.location):\(match.range.location + match.range.length)]")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(match.fullMatch)
                                .font(.system(.caption, design: .monospaced))
                                .padding(4)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(4)
                                .textSelection(.enabled)
                            if !match.groups.isEmpty {
                                ForEach(Array(match.groups.enumerated()), id: \.offset) { gIdx, group in
                                    HStack {
                                        Text("Group \(gIdx + 1):")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(group)
                                            .font(.system(.caption2, design: .monospaced))
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Section("Replace") {
                TextField("Replacement string", text: $viewModel.replacement)
                    .font(.system(.caption, design: .monospaced))
                    .textInputAutocapitalization(.never)
                if !viewModel.replacedText.isEmpty {
                    Text(viewModel.replacedText)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(4)
                        .background(Color.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
                }
            }

            Section("Common Patterns") {
                ForEach(RegexTesterViewModel.commonPatterns, id: \.name) { pattern in
                    Button {
                        viewModel.pattern = pattern.regex
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pattern.name).font(.caption.bold())
                            Text(pattern.regex)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct RegexMatch {
    let fullMatch: String
    let groups: [String]
    let range: NSRange
}

class RegexTesterViewModel: ObservableObject {
    @Published var pattern = "[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}" {
        didSet { evaluate() }
    }
    @Published var inputText = "Contact jules@example.com or support@toolskit.io" {
        didSet { evaluate() }
    }
    @Published var caseInsensitive = false { didSet { evaluate() } }
    @Published var multiline = false { didSet { evaluate() } }
    @Published var dotMatchesNewline = false { didSet { evaluate() } }
    @Published var replacement = "" { didSet { performReplace() } }
    @Published var matches: [RegexMatch] = []
    @Published var replacedText = ""
    @Published var isValid = true

    struct CommonPattern: Identifiable {
        let id = UUID()
        let name: String
        let regex: String
    }

    static let commonPatterns: [CommonPattern] = [
        CommonPattern(name: "Email", regex: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"),
        CommonPattern(name: "URL", regex: "https?://[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=%]+"),
        CommonPattern(name: "IPv4", regex: "\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b"),
        CommonPattern(name: "Phone (US)", regex: "\\(?\\d{3}\\)?[-.\\s]?\\d{3}[-.\\s]?\\d{4}"),
        CommonPattern(name: "Hex Color", regex: "#[0-9A-Fa-f]{6}\\b"),
        CommonPattern(name: "UUID", regex: "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"),
        CommonPattern(name: "Date (YYYY-MM-DD)", regex: "\\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\\d|3[01])"),
    ]

    private func evaluate() {
        guard !pattern.isEmpty else {
            matches = []
            isValid = true
            return
        }

        var options: NSRegularExpression.Options = []
        if caseInsensitive { options.insert(.caseInsensitive) }
        if multiline { options.insert(.anchorsMatchLines) }
        if dotMatchesNewline { options.insert(.dotMatchesLineSeparators) }

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let range = NSRange(inputText.startIndex..<inputText.endIndex, in: inputText)
            let nsMatches = regex.matches(in: inputText, options: [], range: range)

            matches = nsMatches.map { result in
                let fullRange = Range(result.range, in: inputText)!
                let fullMatch = String(inputText[fullRange])

                var groups: [String] = []
                for i in 1..<result.numberOfRanges {
                    if let groupRange = Range(result.range(at: i), in: inputText) {
                        groups.append(String(inputText[groupRange]))
                    }
                }
                return RegexMatch(fullMatch: fullMatch, groups: groups, range: result.range)
            }
            isValid = true
        } catch {
            isValid = false
            matches = []
        }
        performReplace()
    }

    private func performReplace() {
        guard !replacement.isEmpty, !pattern.isEmpty, isValid else {
            replacedText = ""
            return
        }
        var options: NSRegularExpression.Options = []
        if caseInsensitive { options.insert(.caseInsensitive) }
        if multiline { options.insert(.anchorsMatchLines) }
        if dotMatchesNewline { options.insert(.dotMatchesLineSeparators) }

        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let range = NSRange(inputText.startIndex..<inputText.endIndex, in: inputText)
        replacedText = regex.stringByReplacingMatches(in: inputText, options: [], range: range, withTemplate: replacement)
    }
}

#Preview {
    RegexTesterDevToolView()
}
