import SwiftUI

struct URLParserView: View {
    @StateObject private var backend = URLParserBackend()
    @State private var input: String = ""

    var body: some View {
        ToolDetailView(tool: URLParserTool()) {
            VStack(spacing: 24) {
                ToolInputSection("URL") {
                    TextField("Enter URL Here", text: $input)
                        .padding()
                        .onChange(of: input) { _, _ in backend.parse(urlString: input) }
                }

                if !backend.components.isEmpty {
                    ToolInputSection("Parsed Components") {
                        ForEach(backend.components) { item in
                            HStack {
                                Text(item.key).foregroundColor(.secondary)
                                Spacer()
                                Text(item.value).bold()
                            }
                            .padding()
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct URLParserTool: Tool, Sendable {
    let name = "URL Parser"
    let icon = "link.circle"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Break down complex URLs into their individual components"
    let requiresAPI = false
    var view: AnyView { AnyView(URLParserView()) }
}
