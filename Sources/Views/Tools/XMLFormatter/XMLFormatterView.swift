import SwiftUI
struct XMLFormatterView: View {
    @StateObject private var backend = XMLFormatterBackend()
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TextEditor(text: $backend.xml)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .border(Color.gray, width: 1)
                Button("Format XML") { backend.format() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("XML Formatter")
    }
}
struct XMLFormatterTool: Tool {
    let name = "XML Formatter"
    let icon = "chevron.left.slash.chevron.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Format XML"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(XMLFormatterView()) }
}
