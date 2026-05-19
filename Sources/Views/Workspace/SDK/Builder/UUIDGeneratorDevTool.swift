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
    @State private var showingBulkSheet = false

    var body: some View {
        List {
            Section("Current UUID") {
                VStack(spacing: 16) {
                    Text(viewModel.currentUUID)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 12) {
                        Button {
                            viewModel.generate()
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            UIPasteboard.general.string = viewModel.currentUUID
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .padding(10)
                                .background(Color.blue.opacity(0.1), in: Circle())
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Formatting") {
                Toggle("Uppercase", isOn: $viewModel.isUppercase)
                Toggle("Include Hyphens", isOn: $viewModel.includeHyphens)
                Toggle("Braces { }", isOn: $viewModel.includeBraces)
            }

            Section("Bulk Operations") {
                Stepper("Quantity: \(viewModel.bulkCount)", value: $viewModel.bulkCount, in: 1...100)

                Button {
                    showingBulkSheet = true
                    viewModel.generateBulk()
                } label: {
                    Label("Generate Bulk List", systemImage: "list.bullet.rectangle.stack")
                }
            }

            Section {
                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock.arrow.circlepath", description: Text("Generated UUIDs will appear here."))
                } else {
                    ForEach(viewModel.history) { item in
                        HStack {
                            Text(item.title)
                                .font(.system(size: 11, design: .monospaced))
                            Spacer()
                            Button {
                                UIPasteboard.general.string = item.title
                            } label: {
                                Image(systemName: "doc.on.doc").font(.caption)
                            }
                        }
                    }
                    .onDelete { viewModel.history.remove(atOffsets: $0) }
                }
            } header: {
                HStack {
                    Text("History")
                    Spacer()
                    if !viewModel.history.isEmpty {
                        Button("Clear") { viewModel.history.removeAll() }.font(.caption)
                    }
                }
            }
        }
        .navigationTitle("UUID Generator")
        .sheet(isPresented: $showingBulkSheet) {
            BulkUUIDView(uuids: viewModel.bulkResults)
        }
    }
}

struct BulkUUIDView: View {
    let uuids: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(uuids, id: \.self) { uuid in
                Text(uuid).font(.system(size: 12, design: .monospaced))
            }
            .navigationTitle("Bulk UUIDs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Copy All") {
                        UIPasteboard.general.string = uuids.joined(separator: "\n")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

class UUIDGeneratorViewModel: ObservableObject {
    @Published var currentUUID = ""
    @Published var isUppercase = true { didSet { updateCurrent() } }
    @Published var includeHyphens = true { didSet { updateCurrent() } }
    @Published var includeBraces = false { didSet { updateCurrent() } }
    @Published var bulkCount = 10
    @Published var history: [HistoryItem] = []
    @Published var bulkResults: [String] = []

    private var baseUUID = UUID()

    init() {
        generate()
    }

    func generate() {
        baseUUID = UUID()
        updateCurrent()
        history.insert(HistoryItem(title: currentUUID, detail: "v4"), at: 0)
        if history.count > 50 { history.removeLast() }
    }

    func generateBulk() {
        bulkResults = (0..<bulkCount).map { _ in
            format(UUID())
        }
    }

    private func updateCurrent() {
        currentUUID = format(baseUUID)
    }

    private func format(_ uuid: UUID) -> String {
        var s = uuid.uuidString
        if !isUppercase { s = s.lowercased() }
        if !includeHyphens { s = s.replacingOccurrences(of: "-", with: "") }
        if includeBraces { s = "{\(s)}" }
        return s
    }
}

#Preview {
    UUIDGeneratorDevToolView()
}
