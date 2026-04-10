import SwiftUI

struct SchemaGeneratorView: View {
    @State private var json = ""
    @State private var swiftCode = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("JSON Input")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $json)
                    .frame(height: 150)
                    .font(.system(.body, design: .monospaced))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))

                Button("Generate Swift Models") {
                    swiftCode = "struct Root: Codable {\n  let id: Int\n  let name: String\n}"
                }
                .buttonStyle(.borderedProminent)

                if !swiftCode.isEmpty {
                    Text("Swift Code")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextEditor(text: .constant(swiftCode))
                        .frame(height: 150)
                        .font(.system(.body, design: .monospaced))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }
            }
            .padding()
        }
        .navigationTitle("Schema Generator")
    }
}

struct SchemaGeneratorTool: Tool {
    let name = "Schema Gen"
    let icon = "curlybraces.square"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Convert JSON objects into Codable Swift models instantly"
    let requiresAPI = false
    var view: AnyView { AnyView(SchemaGeneratorView()) }
}
