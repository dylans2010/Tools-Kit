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
    @StateObject private var viewModel = UUIDBulkGeneratorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "UUID Bulk Generator",
                description: "Create batches of unique identifiers for seeding data or load testing.",
                icon: "barcode.viewfinder"
            )
            .padding()

            Form {
                Section("Quantity") {
                    Stepper("Count: \(viewModel.count)", value: $viewModel.count, in: 1...1000)
                    Button("Generate Batch") { viewModel.generateBatch() }
                }

                Section("Batch Output") {
                    TextEditor(text: .constant(viewModel.output))
                        .frame(height: 200)
                        .font(.system(.caption, design: .monospaced))

                    ExportPanel(content: viewModel.output, filename: "uuids.txt")
                }
            }
        }
    }
}

class UUIDBulkGeneratorViewModel: ObservableObject {
    @Published var count = 10
    @Published var output = ""

    func generateBatch() {
        var results: [String] = []
        for _ in 0..<count {
            results.append(UUID().uuidString)
        }
        output = results.joined(separator: "\n")
    }
}
