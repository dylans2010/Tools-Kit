
import SwiftUI

struct ConnectorGraphQLView: View {
    @State private var query = "{ user { id name email } }"
    @State private var schema: String = ""

    var body: some View {
        Form {
            Section("GraphQL Query") {
                TextEditor(text: $query)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 150)
            }

            Section("Generated Schema") {
                if schema.isEmpty {
                    Button("Infer Schema from Query") { infer() }
                } else {
                    Text(schema).font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary)
                    Button("Reset Schema") { schema = "" }
                }
            }
        }
        .navigationTitle("GraphQL")
    }

    private func infer() {
        // Simple real logic to infer a basic schema string from the query
        let fields = query.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").split(separator: " ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        schema = "type Query {\n  " + fields.joined(separator: ": String\n  ") + ": String\n}"
    }
}
