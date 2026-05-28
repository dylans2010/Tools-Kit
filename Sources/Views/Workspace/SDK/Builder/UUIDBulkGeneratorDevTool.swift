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
        Form {
            Section(header: Text("Quantity")) {
                Stepper("Count: \(viewModel.count)", value: $viewModel.count, in: 1...1000)
                Button("Generate Batch") { viewModel.generateBatch() }
            }

            Section(header: Text("Batch Output")) {
                TextEditor(text: .constant(viewModel.output))
                    .frame(height: 200)
                    .font(.system(.caption, design: .monospaced))

                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.output
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("uuids.txt")
                        try? viewModel.output.write(to: fileURL, atomically: true, encoding: .utf8)
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
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

#Preview {
    UUIDBulkGeneratorView()
}
