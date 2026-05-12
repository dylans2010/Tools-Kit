import SwiftUI

struct SchemaGeneratorView: View {
    @StateObject private var backend = SchemaGeneratorBackend()
    @State private var description: String = ""
    @State private var format: String = "SQL"

    let formats = ["SQL", "JSON Schema", "Swift Model", "GraphQL"]

    var body: some View {
        ToolDetailView(tool: SchemaGeneratorTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(formats, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }

                ToolInputSection("Description") {
                    TextEditor(text: $description)
                        .frame(height: 120)
                        .padding(8)
                }

                Button(action: {
                    Task { await backend.generateSchema(from: description, format: format) }
                }) {
                    if backend.isProcessing {
                        ProgressView()
                    } else {
                        Text("Generate Schema")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.isEmpty || backend.isProcessing)

                if !backend.schema.isEmpty {
                    ToolOutputView("Generated Schema", value: backend.schema)
                }
            }
        }
    }
}

struct SchemaGeneratorTool: Tool, Sendable {
    let name = "Schema Generator"
    let icon = "tablecells.badge.ellipsis"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Generate database schemas or code models from natural language"
    let requiresAPI = true
    var view: AnyView { AnyView(SchemaGeneratorView()) }
}
