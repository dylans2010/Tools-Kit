import SwiftUI

struct AdvancedRegexDebuggerDevTool: DevTool {
    let id = "advanced-regex-debugger"
    let name = "Advanced Regex Debugger"
    let category: DevToolCategory = .utilities
    let icon = "bolt.circle"
    let description = "Test regex with capture group highlighting"

    func render() -> some View {
        AdvancedRegexDebuggerView()
    }
}

struct AdvancedRegexDebuggerView: View {
    @State private var pattern = "[a-z]+"
    @State private var text = "hello world 123"
    @State private var matches = ""

    var body: some View {
        Form {
            Section("Pattern") {
                TextField("Regex Pattern", text: $pattern)
                    .font(.system(.body, design: .monospaced))
            }
            Section("Test Text") {
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 100)
            }
            Button("Find Matches") {
                find()
            }
            .frame(maxWidth: .infinity)

            if !matches.isEmpty {
                Section("Matches Found") {
                    Text(matches)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
    }

    private func find() {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            if results.isEmpty {
                matches = "No matches found."
            } else {
                matches = results.enumerated().map { i, result in
                    "Match \(i+1): \(nsString.substring(with: result.range))"
                }.joined(separator: "\n")
            }
        } catch {
            matches = "Invalid Pattern: \(error.localizedDescription)"
        }
    }
}
