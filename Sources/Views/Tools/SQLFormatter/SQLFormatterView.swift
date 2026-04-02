import SwiftUI
struct SQLFormatterView: View {
    @StateObject private var backend = SQLFormatterBackend()
    var body: some View {
        VStack(spacing: 20) {
            TextEditor(text: $backend.sql)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray, width: 1)

            Button("Format SQL") {
                backend.format()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("SQL Formatter")
    }
}
struct SQLFormatterTool: Tool {
    let name = "SQL Formatter"
    let icon = "tablecells.fill"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Format SQL"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(SQLFormatterView()) }
}
