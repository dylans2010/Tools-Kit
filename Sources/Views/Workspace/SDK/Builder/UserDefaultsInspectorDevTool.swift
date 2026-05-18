import SwiftUI

struct UserDefaultsInspectorDevTool: DevTool {
    let id = "user-defaults-inspector"
    let name = "UserDefaults Inspector"
    let category = DevToolCategory.storage
    let icon = "externaldrive.badge.person.ivory"
    let description = "View and edit UserDefaults entries"

    func render() -> some View {
        UserDefaultsInspectorView()
    }
}

struct UserDefaultsInspectorView: View {
    @StateObject private var viewModel = UserDefaultsInspectorViewModel()
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "UserDefaults Inspector",
                description: "Inspect persisted user preferences and modify settings for testing purposes.",
                icon: "externaldrive.badge.person.ivory"
            )
            .padding()

            VStack {
                TextField("Search keys...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                List {
                    ForEach(filteredEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.key).font(.subheadline.bold()).foregroundStyle(Color.accentColor)
                            HStack {
                                Text(entry.value).font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Button("Edit") { viewModel.startEditing(entry) }
                                    .font(.caption)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.delete)
                }
            }
        }
        .onAppear { viewModel.load() }
        .sheet(item: $viewModel.editingEntry) { entry in
            EditEntryView(entry: entry, onSave: { key, val in
                viewModel.save(key: key, value: val)
                viewModel.editingEntry = nil
            })
        }
    }

    private var filteredEntries: [UDEntry] {
        if searchText.isEmpty { return viewModel.entries }
        return viewModel.entries.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
    }
}

struct UDEntry: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

class UserDefaultsInspectorViewModel: ObservableObject {
    @Published var entries: [UDEntry] = []
    @Published var editingEntry: UDEntry?

    func load() {
        let dict = UserDefaults.standard.dictionaryRepresentation()
        entries = dict.map { UDEntry(key: $0.key, value: "\($0.value)") }
                      .sorted { $0.key < $1.key }
    }

    func startEditing(_ entry: UDEntry) {
        editingEntry = entry
    }

    func save(key: String, value: String) {
        UserDefaults.standard.set(value, forKey: key)
        load()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            UserDefaults.standard.removeObject(forKey: entries[index].key)
        }
        load()
    }
}

struct EditEntryView: View {
    let entry: UDEntry
    @State private var value: String
    var onSave: (String, String) -> Void

    init(entry: UDEntry, onSave: @escaping (String, String) -> Void) {
        self.entry = entry
        self._value = State(initialValue: entry.value)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Key") { Text(entry.key) }
                Section("Value") {
                    TextEditor(text: $value)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Entry")
            .toolbar {
                Button("Save") { onSave(entry.key, value) }
            }
        }
    }
}
