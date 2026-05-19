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
    @State private var showingQuickReference = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pattern").font(.caption2.bold()).foregroundStyle(.secondary)
                    TextField("e.g. [0-9]+", text: $viewModel.pattern)
                        .textFieldStyle(.plain)
                        .font(.system(.subheadline, design: .monospaced))
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(viewModel.isValid ? Color.clear : Color.red, lineWidth: 1))

                    if !viewModel.isValid {
                        Text("Invalid Regular Expression").font(.caption2).foregroundStyle(.red)
                    }
                }

                HStack {
                    Button {
                        showingQuickReference = true
                    } label: {
                        Label("Cheat Sheet", systemImage: "info.circle")
                            .font(.caption)
                    }

                    Spacer()

                    Menu {
                        Button("Email") { viewModel.pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}" }
                        Button("URL") { viewModel.pattern = "https?://(?:www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b(?:[-a-zA-Z0-9()@:%_\\+.~#?&//=]*)" }
                        Button("Phone") { viewModel.pattern = "^[\\+]?[(]?[0-9]{3}[)]?[-\\s\\.]?[0-9]{3}[-\\s\\.]?[0-9]{4,6}$" }
                        Button("Date (YYYY-MM-DD)") { viewModel.pattern = "\\d{4}-\\d{2}-\\d{2}" }
                    } label: {
                        Label("Presets", systemImage: "list.bullet.rectangle.stack")
                            .font(.caption)
                    }
                }
            } header: {
                Text("Regex Configuration")
            }

            Section("Input Text") {
                TextEditor(text: $viewModel.inputText)
                    .frame(minHeight: 120)
                    .font(.system(.subheadline, design: .monospaced))
            }

            Section {
                if viewModel.matches.isEmpty {
                    ContentUnavailableView("No Matches", systemImage: "magnifyingglass", description: Text("No substrings match the given pattern."))
                } else {
                    ForEach(viewModel.matches, id: \.id) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Match \(result.index)")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.blue)
                                Spacer()
                                Text("Range: \(result.range.lowerBound)...\(result.range.upperBound)")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }

                            Text(result.value)
                                .font(.system(.subheadline, design: .monospaced))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                HStack {
                    Text("Results")
                    Spacer()
                    if !viewModel.matches.isEmpty {
                        Text("\(viewModel.matches.count) found").font(.caption2)
                    }
                }
            }
        }
        .navigationTitle("Regex Tester")
        .sheet(isPresented: $showingQuickReference) {
            RegexCheatSheetView()
        }
    }
}

struct RegexMatchResult: Identifiable {
    let id = UUID()
    let index: Int
    let value: String
    let range: NSRange
}

struct RegexCheatSheetView: View {
    @Environment(\.dismiss) var dismiss

    let items = [
        (".", "Any character"),
        ("\\d", "Digit [0-9]"),
        ("\\w", "Word character [a-zA-Z0-9_]"),
        ("\\s", "Whitespace"),
        ("^ / $", "Start / End of line"),
        ("*", "0 or more"),
        ("+", "1 or more"),
        ("?", "0 or 1"),
        ("{n}", "Exactly n times"),
        ("[abc]", "Any of a, b, or c")
    ]

    var body: some View {
        NavigationStack {
            List(items, id: \.0) { item in
                HStack {
                    Text(item.0).font(.system(.body, design: .monospaced)).bold()
                    Spacer()
                    Text(item.1).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Regex Cheat Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
        .presentationDetents([.medium])
    }
}

class RegexTesterViewModel: ObservableObject {
    @Published var pattern = "[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}" {
        didSet { evaluate() }
    }
    @Published var inputText = "Contact jules@example.com or support@toolskit.io" {
        didSet { evaluate() }
    }
    @Published var matches: [RegexMatchResult] = []
    @Published var isValid = true

    private func evaluate() {
        guard !pattern.isEmpty else {
            matches = []
            isValid = true
            return
        }

        do {
            let options: NSRegularExpression.Options = [.caseInsensitive]
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let range = NSRange(inputText.startIndex..<inputText.endIndex, in: inputText)
            let nsMatches = regex.matches(in: inputText, options: [], range: range)

            matches = nsMatches.enumerated().compactMap { i, result in
                guard let range = Range(result.range, in: inputText) else { return nil }
                return RegexMatchResult(index: i + 1, value: String(inputText[range]), range: result.range)
            }
            isValid = true
        } catch {
            isValid = false
            matches = []
        }
    }
}

#Preview {
    RegexTesterDevToolView()
}
