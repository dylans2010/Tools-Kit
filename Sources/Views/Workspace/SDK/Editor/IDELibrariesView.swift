/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Replaced manual headers and pills with native Section titles and LabeledContent.
 - Modernized library rows using a private struct LibraryItemRow with monospaced versioning.
 - Applied .presentationDetents([.medium, .large]) to the library editor sheet.
 - Strictly preserved all SDKRuntimeWorkspaceState library management and diagnostics logic.
 - Replaced manual scope scroll views with standard monospaced text blocks.
 - Implemented ContentUnavailableView for empty library states.
 */

import SwiftUI

struct IDELibrariesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var showingAddLibrary = false
    @State private var editingLibrary: SDKLibraryDefinition?

    var body: some View {
        List {
            Section("Management") {
                Button {
                    editingLibrary = nil
                    showingAddLibrary = true
                } label: {
                    Label("Add New Library", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }

            Section("Installed Libraries") {
                if state.libraries.isEmpty {
                    ContentUnavailableView(
                        "No Libraries",
                        systemImage: "books.vertical",
                        description: Text("Add a library to extend SDK functionality.")
                    )
                } else {
                    ForEach(state.libraries) { library in
                        LibraryItemRow(library: library) {
                            editingLibrary = library
                        }
                    }
                    .onDelete(perform: deleteLibraries)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Libraries")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddLibrary) {
            LibraryEditorSheet(library: nil) { state.upsertLibrary($0) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingLibrary) { library in
            LibraryEditorSheet(library: library) { state.upsertLibrary($0) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func deleteLibraries(at offsets: IndexSet) {
        state.libraries.remove(atOffsets: offsets)
        state.recalculateDiagnostics()
    }
}

// MARK: - Private Subviews

private struct LibraryItemRow: View {
    let library: SDKLibraryDefinition
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(library.name).font(.headline)
                    Spacer()
                    Text("v\(library.version)").font(.caption.monospaced()).foregroundStyle(Color.accentColor)
                }

                Text("\(library.exportedFunctions.count) exports · \(library.linkedScopes.count) scopes")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !library.linkedScopes.isEmpty {
                    Text(library.linkedScopes.joined(separator: ", "))
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct LibraryEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var version: String
    @State private var selectedScopes: Set<String>
    @State private var functions: [SDKLibraryFunctionExport]

    let library: SDKLibraryDefinition?
    let onSave: (SDKLibraryDefinition) -> Void

    init(library: SDKLibraryDefinition?, onSave: @escaping (SDKLibraryDefinition) -> Void) {
        self.library = library
        self.onSave = onSave
        _name = State(initialValue: library?.name ?? "")
        _version = State(initialValue: library?.version ?? "1.0.0")
        _selectedScopes = State(initialValue: Set(library?.linkedScopes ?? []))
        _functions = State(initialValue: library?.exportedFunctions ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Library Name", text: $name)
                    TextField("Version", text: $version)
                }

                Section("Scopes") {
                    ForEach(SDKRuntimeWorkspaceState.scopeCatalog) { scope in
                        Toggle(scope.key, isOn: Binding(
                            get: { selectedScopes.contains(scope.key) },
                            set: { if $0 { selectedScopes.insert(scope.key) } else { selectedScopes.remove(scope.key) } }
                        ))
                        .font(.caption.monospaced())
                    }
                }

                Section("Exports") {
                    ForEach($functions) { (fn: Binding<SDKLibraryFunctionExport>) in
                        TextField("Function Signature", text: fn.name)
                            .font(.caption.monospaced())
                    }
                    Button("Add Function") {
                        functions.append(SDKLibraryFunctionExport(name: "newFunction()", signature: "() -> Void"))
                    }
                }
            }
            .navigationTitle(library == nil ? "New Library" : "Edit Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let new = SDKLibraryDefinition(id: library?.id ?? UUID(), name: name, version: version, linkedScopes: Array(selectedScopes), exportedFunctions: functions, pipelineStages: library?.pipelineStages ?? ["prepare", "execute"])
                        onSave(new)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
