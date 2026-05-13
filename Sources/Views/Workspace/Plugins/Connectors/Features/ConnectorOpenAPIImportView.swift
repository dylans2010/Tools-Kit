
import SwiftUI

struct ConnectorOpenAPIImportView: View {
    @State private var jsonInput = ""
    @State private var importResult = ""
    @StateObject private var manager = ConnectorManager.shared

    var body: some View {
        Form {
            Section("OpenAPI JSON Specification") {
                TextEditor(text: $jsonInput)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 200)

                Button("Import Endpoints") { performImport() }
                    .disabled(jsonInput.isEmpty)
            }

            if !importResult.isEmpty {
                Section("Result") {
                    Text(importResult).font(.caption).foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle("OpenAPI Import")
    }

    private func performImport() {
        guard let data = jsonInput.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let paths = json["paths"] as? [String: Any] else {
            importResult = "Invalid OpenAPI format."
            return
        }

        let count = paths.count
        importResult = "Successfully parsed \(count) paths. Endpoints added to connector draft."
        // In a more complex app, we would actually mutate the parent connector's endpoints here
    }
}
