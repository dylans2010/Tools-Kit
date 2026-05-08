import SwiftUI

struct IDELibrariesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var showingAddLibrary = false
    @State private var editingLibrary: SDKLibraryDefinition?

    var body: some View {
        List {
            Section {
                Button {
                    editingLibrary = nil
                    showingAddLibrary = true
                } label: {
                    Label("Add New Library", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            } header: {
                SDKSectionHeader("Management", subtitle: "Library definitions", systemImage: "shippingbox")
            }

            Section {
                if state.libraries.isEmpty {
                    ContentUnavailableView("No Libraries", systemImage: "books.vertical", description: Text("Add a library to extend SDK functionality."))
                } else {
                    ForEach(state.libraries) { library in
                        libraryRow(for: library)
                    }
                    .onDelete(perform: deleteLibraries)
                }
            } header: {
                Text("INSTALLED LIBRARIES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Libraries")
        .sheet(isPresented: $showingAddLibrary) {
            LibraryEditorSheet(library: editingLibrary) { newLibrary in
                state.upsertLibrary(newLibrary)
            }
        }
        .sheet(item: $editingLibrary) { library in
            LibraryEditorSheet(library: library) { updatedLibrary in
                state.upsertLibrary(updatedLibrary)
            }
        }
    }

    private func libraryRow(for library: SDKLibraryDefinition) -> some View {
        Button {
            editingLibrary = library
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(library.name)
                        .font(.headline)
                    Spacer()
                    Text("v\(library.version)")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                }

                Text("\(library.exportedFunctions.count) exports • \(library.linkedScopes.count) scopes • \(library.pipelineStages.count) stages")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !library.linkedScopes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(library.linkedScopes, id: \.self) { scope in
                                Text(scope)
                                    .font(.system(size: 8, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func deleteLibraries(at offsets: IndexSet) {
        state.libraries.remove(atOffsets: offsets)
        state.recalculateDiagnostics()
    }
}

struct LibraryEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var version: String
    @State private var selectedScopes: Set<String>
    @State private var functions: [SDKLibraryFunctionExport]
    @State private var stages: [String]

    let library: SDKLibraryDefinition?
    let onSave: (SDKLibraryDefinition) -> Void

    init(library: SDKLibraryDefinition?, onSave: @escaping (SDKLibraryDefinition) -> Void) {
        self.library = library
        self.onSave = onSave
        _name = State(initialValue: library?.name ?? "")
        _version = State(initialValue: library?.version ?? "1.0.0")
        _selectedScopes = State(initialValue: Set(library?.linkedScopes ?? []))
        _functions = State(initialValue: library?.exportedFunctions ?? [])
        _stages = State(initialValue: library?.pipelineStages ?? ["validate", "execute"])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Library Name", text: $name)
                    TextField("Version", text: $version)
                }

                Section("Scopes") {
                    ForEach(SDKRuntimeWorkspaceState.scopeCatalog) { scope in
                        Toggle(scope.key, isOn: Binding(
                            get: { selectedScopes.contains(scope.key) },
                            set: { if $0 { selectedScopes.insert(scope.key) } else { selectedScopes.remove(scope.key) } }
                        ))
                        .font(.system(.caption, design: .monospaced))
                    }
                }

                Section("Exported Functions") {
                    ForEach(functions.indices, id: \.self) { index in
                        HStack {
                            TextField("Name", text: $functions[index].name)
                            TextField("Signature", text: $functions[index].signature)
                        }
                    }
                    Button("Add Function") {
                        functions.append(SDKLibraryFunctionExport(name: "newFunction", signature: "() -> Void"))
                    }
                }
            }
            .navigationTitle(library == nil ? "New Library" : "Edit Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newLibrary = SDKLibraryDefinition(
                            id: library?.id ?? UUID(),
                            name: name,
                            version: version,
                            linkedScopes: Array(selectedScopes),
                            exportedFunctions: functions,
                            pipelineStages: stages
                        )
                        onSave(newLibrary)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
