import SwiftUI

struct UUIDGeneratorDevTool: DevTool {
    let id = "uuid-generator"
    let name = "UUID Generator"
    let category = DevToolCategory.data
    let icon = "barcode"
    let description = "Generate unique identifiers (UUID v4)"

    func render() -> some View {
        UUIDGeneratorDevToolView()
    }
}

struct UUIDGeneratorDevToolView: View {
    @StateObject private var viewModel = UUIDGeneratorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "UUID Generator",
                description: "Generate cryptographically secure unique identifiers for database keys and object mapping.",
                icon: "barcode"
            )
            .padding()

            Form {
                Section("Generated UUID") {
                    Text(viewModel.currentUUID)
                        .font(.system(.headline, design: .monospaced))
                        .textSelection(.enabled)

                    Button("Generate New") { viewModel.generate() }
                }

                Section("Configuration") {
                    Toggle("Uppercase", isOn: $viewModel.isUppercase)
                    Toggle("Include Hyphens", isOn: $viewModel.includeHyphens)
                }

                Section("History") {
                    HistoryView(history: viewModel.history) { item in
                        viewModel.currentUUID = item.title
                    } onClear: {
                        viewModel.history.removeAll()
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}

class UUIDGeneratorViewModel: ObservableObject {
    @Published var currentUUID = UUID().uuidString
    @Published var isUppercase = true
    @Published var includeHyphens = true
    @Published var history: [HistoryItem] = []

    func generate() {
        var uuid = UUID().uuidString
        if !isUppercase { uuid = uuid.lowercased() }
        if !includeHyphens { uuid = uuid.replacingOccurrences(of: "-", with: "") }

        currentUUID = uuid
        history.insert(HistoryItem(title: uuid, detail: "Generated"), at: 0)
    }
}
