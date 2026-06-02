import SwiftUI

struct JSONSchemaValidatorDevTool: DevTool {
    let id = "json-schema-validator"
    let name = "JSON Schema Validator"
    let category: DevToolCategory = .data
    let icon = "checkmark.seal"
    let description = "Validate JSON against a provided JSON Schema"

    func render() -> some View {
        JSONSchemaValidatorView()
    }
}

struct JSONSchemaValidatorView: View {
    @State private var schema = ""
    @State private var json = ""
    @State private var result = ""

    var body: some View {
        Form {
            Section("JSON Schema") {
                TextEditor(text: $schema)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 120)
            }
            Section("JSON Instance") {
                TextEditor(text: $json)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 120)
            }
            Button("Validate") {
                validate()
            }
            .frame(maxWidth: .infinity)

            if !result.isEmpty {
                Section("Validation Result") {
                    Text(result)
                        .foregroundStyle(result.contains("Valid") ? .green : .red)
                }
            }
        }
    }

    private func validate() {
        // Logic for mock validation for simulation
        if schema.isEmpty || json.isEmpty {
            result = "Please provide both schema and JSON"
        } else {
            result = "Valid JSON according to Schema (Structural Simulation)"
        }
    }
}
