import SwiftUI
struct SQLFormatterView: View {
    @StateObject private var backend = SQLFormatterBackend()
    var body: some View { VStack { TextEditor(text: $backend.sql); Button("Format") { backend.format() } }.navigationTitle("SQL Formatter") }
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
