import SwiftUI

struct RegexTesterView: View {
    @StateObject private var backend = RegexTesterBackend()

    var body: some View {
        Form {
            Section {
                TextField("Pattern", text: $backend.pattern)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .onChange(of: backend.pattern) { _, _ in backend.findMatches() }
            } header: {
                Text("Regex Pattern")
            }

            Section {
                TextEditor(text: $backend.testText)
                    .frame(height: 150)
                    .onChange(of: backend.testText) { _, _ in backend.findMatches() }
            } header: {
                Text("Test Text")
            }

            Section {
                List(backend.matches, id: \.self) { match in
                    Text(match)
                        .font(.system(.body, design: .monospaced))
                }
                .frame(minHeight: 100)
            } header: {
                Text("Matches (\(backend.matches.count))")
            }
        }
        .navigationTitle("Regex Tester")
    }
}

struct RegexTesterTool: Tool, Sendable {
    let name = "Regex Tester"
    let icon = "text.magnifyingglass"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Live regex matching and testing"
    let requiresAPI = false

    var view: AnyView {
        AnyView(RegexTesterView())
    }
}
