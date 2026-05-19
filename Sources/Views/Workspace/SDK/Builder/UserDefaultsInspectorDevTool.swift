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
    @State private var selectedDomain = "standard"

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search keys...", text: $searchText)
                }

                Picker("Domain", selection: $selectedDomain) {
                    Text("Standard").tag("standard")
                    Text("Volatile").tag("volatile")
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }

            Section("Entries (\(filteredEntries.count))") {
                if filteredEntries.isEmpty {
                    ContentUnavailableView("No Results", systemImage: "archivebox", description: Text("No keys found matching your search."))
                } else {
                    ForEach(filteredEntries) { entry in
                        UDEntryRow(entry: entry,
                                 onEdit: { viewModel.startEditing(entry) },
                                 onCopy: { UIPasteboard.general.string = entry.value })
                    }
                    .onDelete(perform: viewModel.delete)
                }
            }
        }
        .navigationTitle("UserDefaults")
        .refreshable { viewModel.load() }
        .onAppear { viewModel.load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $viewModel.editingEntry) { entry in
            EditEntryView(entry: entry, onSave: { key, val in
                viewModel.save(key: key, value: val)
                viewModel.editingEntry = nil
            })
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddEntryView(onAdd: viewModel.save)
        }
    }

    private var filteredEntries: [UDEntry] {
        let entries = viewModel.entries
        if searchText.isEmpty { return entries }
        return entries.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
    }
}

struct UDEntryRow: View {
    let entry: UDEntry
    let onEdit: () -> Void
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.key)
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                Spacer()
                Text(entry.type)
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(4)
            }

            HStack {
                Text(entry.value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(action: onCopy) {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
            Button(role: .destructive) {
                // Trigger delete
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct UDEntry: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

struct UDEntry: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    let type: String
}

class UserDefaultsInspectorViewModel: ObservableObject {
    @Published var entries: [UDEntry] = []
    @Published var editingEntry: UDEntry?
    @Published var showAddSheet = false

    func load() {
        let dict = UserDefaults.standard.dictionaryRepresentation()
        entries = dict.map { key, value in
            let typeString: String
            if value is String { typeString = "String" }
            else if value is Bool { typeString = "Bool" }
            else if value is Int { typeString = "Int" }
            else if value is Double { typeString = "Double" }
            else if value is Array<Any> { typeString = "Array" }
            else if value is Dictionary<String, Any> { typeString = "Dict" }
            else { typeString = "Other" }

            return UDEntry(key: key, value: "\(value)", type: typeString)
        }.sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
    }

    func startEditing(_ entry: UDEntry) {
        editingEntry = entry
    }

    func save(key: String, value: String) {
        // Simple string save, could be improved to handle types
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

struct AddEntryView: View {
    @State private var key = ""
    @State private var value = ""
    var onAdd: (String, String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Key", text: $key)
                    .autocorrectionDisabled()
                TextField("Value", text: $value)
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(key, value)
                        dismiss()
                    }
                    .disabled(key.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
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

#Preview {
    UserDefaultsInspectorView()
}
