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

            Section {
                HStack {
                    Text("History")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        viewModel.history.removeAll()
                    }
                    .font(.caption)
                    .disabled(viewModel.history.isEmpty)
                }

                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock", description: Text("Your activity will appear here."))
                        .frame(height: 200)
                } else {
                    List {
                        ForEach(viewModel.history) { item in
                            Button {
                                viewModel.currentUUID = item.title
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.subheadline.bold())
                                    Text(item.detail)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .foregroundStyle(.secondary)
                                    Text(item.timestamp, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 300)
                }
            } header: {
                Text("History")
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

#Preview {
    UUIDGeneratorDevToolView()
}
