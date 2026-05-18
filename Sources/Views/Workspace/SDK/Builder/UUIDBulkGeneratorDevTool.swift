import SwiftUI

struct UUIDBulkGeneratorDevTool: DevTool {
    let id = "uuid-bulk-generator"
    let name = "UUID Bulk Generator"
    let category = DevToolCategory.data
    let icon = "barcode.viewfinder"
    let description = "Generate multiple UUIDs at once"

    func render() -> some View {
        UUIDBulkGeneratorView()
    }
}

struct UUIDBulkGeneratorView: View {
    @State private var count = 10.0
    @State private var results: [String] = []

    var body: some View {
        Form {
            Section("Settings") {
                HStack {
                    Text("Count: \(Int(count))")
                    Slider(value: $count, in: 1...100, step: 1)
                }
                Button("Generate") {
                    results = (0..<Int(count)).map { _ in UUID().uuidString }
                }
            }

            if !results.isEmpty {
                Section("Results") {
                    Text(results.joined(separator: "\n"))
                        .font(.monospaced(.caption2)())
                        .textSelection(.enabled)

                    Button {
                        UIPasteboard.general.string = results.joined(separator: "\n")
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}
