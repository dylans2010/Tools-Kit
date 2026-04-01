import SwiftUI

@available(macOS 11.0, *)
struct RegexTesterView: View {
    @StateObject private var backend = RegexTesterBackend()

    var body: some View {
        Form {
            Section(header: Text("Regex Pattern")) {
                TextField("Pattern", text: $backend.pattern)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: backend.pattern) { _ in backend.findMatches() }
            }

            Section(header: Text("Test Text")) {
                TextEditor(text: $backend.testText)
                    .frame(height: 150)
                    .onChange(of: backend.testText) { _ in backend.findMatches() }
            }

            Section(header: Text("Matches (\(backend.matches.count))")) {
                List(backend.matches, id: \.self) { match in
                    Text(match)
                        .font(.system(.body, design: .monospaced))
                }
                .frame(minHeight: 100)
            }
        }
        .navigationTitle("Regex Tester")
    }
}

@available(macOS 11.0, *)
struct RegexTesterTool: Tool {
    let name = "Regex Tester"
    let icon = "text.magnifyingglass"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Live regex matching and testing"

    var view: AnyView {
        AnyView(RegexTesterView())
    }
}
