import SwiftUI

struct RegexTesterTool: DevTool {
    let id = UUID()
    let name = "Regex Tester"
    let category: DevToolCategory = .utilities
    let icon = "magnifyingglass"
    let description = "Test regular expressions with live matching"
    func render() -> some View { RegexTesterDevToolView() }
}

struct RegexTesterDevToolView: View {
    @State private var pattern = ""
    @State private var testString = ""
    @State private var matches: [String] = []
    @State private var matchCount = 0
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section("Pattern") {
                TextField("Regular expression", text: $pattern)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Section("Test String") {
                TextEditor(text: $testString)
                    .frame(minHeight: 80)
                    .font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Test") { testRegex() }
                    .disabled(pattern.isEmpty || testString.isEmpty)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if matchCount > 0 {
                Section("Matches (\(matchCount))") {
                    ForEach(Array(matches.enumerated()), id: \.offset) { idx, match in
                        HStack {
                            Text("\(idx + 1).").font(.caption).foregroundStyle(.secondary).frame(width: 24)
                            Text(match).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                        }
                    }
                }
            } else if errorMsg == nil && !pattern.isEmpty {
                Section { Text("No matches found").foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Regex Tester")
    }

    private func testRegex() {
        errorMsg = nil; matches.removeAll()
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(testString.startIndex..., in: testString)
            let results = regex.matches(in: testString, range: range)
            matchCount = results.count
            matches = results.compactMap { result in
                guard let r = Range(result.range, in: testString) else { return nil }
                return String(testString[r])
            }
        } catch {
            errorMsg = "Invalid regex: \(error.localizedDescription)"
            matchCount = 0
        }
    }
}
