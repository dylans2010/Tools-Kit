import SwiftUI

struct IDELibrariesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var showingEditor = false
    @State private var editingLibrary: SDKLibraryDefinition?
    @State private var resolutionState: ResolutionState = .idle

    enum ResolutionState: String {
        case idle = "Idle"
        case resolving = "Resolving"
        case resolved = "Resolved"
        case failed = "Failed"
    }

    var body: some View {
        List {
            Section("Package Resolution") {
                LabeledContent("State", value: resolutionState.rawValue)
                LabeledContent("Libraries", value: "\(state.libraries.count)")
                LabeledContent("Exports", value: "\(state.libraries.reduce(0) { $0 + $1.exportedFunctions.count })")
                Button {
                    resolvePackages()
                } label: {
                    Label("Resolve Dependencies", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("Library Operations") {
                Button {
                    editingLibrary = nil
                    showingEditor = true
                } label: {
                    Label("Install Library", systemImage: "plus")
                }
                Button {
                    updateAllLibraries()
                } label: {
                    Label("Update All", systemImage: "square.and.arrow.down")
                }
                .disabled(state.libraries.isEmpty)
            }

            Section("Installed Libraries") {
                if state.libraries.isEmpty {
                    ContentUnavailableView(
                        "No Libraries",
                        systemImage: "books.vertical",
                        description: Text("Install a library to begin building module relationships.")
                    )
                } else {
                    ForEach(state.libraries) { library in
                        Button {
                            editingLibrary = library
                        } label: {
                            LibraryRow(library: library, allLibraries: state.libraries)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteLibraries)
                }
            }
        }
        .navigationTitle("Libraries")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditor) {
            LibraryEditorSheet(library: nil) { state.upsertLibrary($0) }
        }
        .sheet(item: $editingLibrary) { library in
            LibraryEditorSheet(library: library) { state.upsertLibrary($0) }
        }
    }

    private func deleteLibraries(at offsets: IndexSet) {
        state.libraries.remove(atOffsets: offsets)
        state.recalculateDiagnostics()
    }

    private func resolvePackages() {
        resolutionState = .resolving
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            resolutionState = state.libraries.isEmpty ? .failed : .resolved
        }
    }

    private func updateAllLibraries() {
        state.libraries = state.libraries.map { library in
            var updated = library
            updated.version = bumpPatch(updated.version)
            return updated
        }
        state.recalculateDiagnostics()
    }

    private func bumpPatch(_ version: String) -> String {
        let parts = version.split(separator: ".").map { Int($0) ?? 0 }
        let major = parts.indices.contains(0) ? parts[0] : 1
        let minor = parts.indices.contains(1) ? parts[1] : 0
        let patch = (parts.indices.contains(2) ? parts[2] : 0) + 1
        return "\(major).\(minor).\(patch)"
    }
}

private struct LibraryRow: View {
    let library: SDKLibraryDefinition
    let allLibraries: [SDKLibraryDefinition]

    private var linkedLibraries: [SDKLibraryDefinition] {
        allLibraries.filter { library.dependencies.contains($0.name) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(library.name, systemImage: "books.vertical")
                    .font(.subheadline.bold())
                Spacer()
                Text("v\(library.version)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Exports", value: "\(library.exportedFunctions.count)")
                .font(.caption)
            LabeledContent("Scopes", value: library.linkedScopes.isEmpty ? "None" : library.linkedScopes.joined(separator: ", "))
                .font(.caption)

            if linkedLibraries.isEmpty {
                Text("No linked module dependencies")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Module Links: \(linkedLibraries.map(\.name).joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct LibraryEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var version: String
    @State private var selectedScopes: Set<String>
    @State private var functions: [SDKLibraryFunctionExport]
    @State private var dependencies: String

    let library: SDKLibraryDefinition?
    let onSave: (SDKLibraryDefinition) -> Void

    init(library: SDKLibraryDefinition?, onSave: @escaping (SDKLibraryDefinition) -> Void) {
        self.library = library
        self.onSave = onSave
        _name = State(initialValue: library?.name ?? "")
        _version = State(initialValue: library?.version ?? "1.0.0")
        _selectedScopes = State(initialValue: Set(library?.linkedScopes ?? []))
        _functions = State(initialValue: library?.exportedFunctions ?? [])
        _dependencies = State(initialValue: library?.dependencies.joined(separator: ",") ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Library Name", text: $name)
                    TextField("Version", text: $version)
                }

                Section("Dependencies") {
                    TextField("Comma-separated module names", text: $dependencies)
                        .font(.caption)
                }

                Section("Scopes") {
                    ForEach(SDKRuntimeWorkspaceState.scopeCatalog) { scope in
                        Toggle(scope.key, isOn: Binding(
                            get: { selectedScopes.contains(scope.key) },
                            set: { if $0 { selectedScopes.insert(scope.key) } else { selectedScopes.remove(scope.key) } }
                        ))
                        .font(.caption)
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
            .navigationTitle(library == nil ? "Install Library" : "Edit Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let new = SDKLibraryDefinition(
                            id: library?.id ?? UUID(),
                            name: name,
                            version: version,
                            linkedScopes: Array(selectedScopes),
                            dependencies: dependencies
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty },
                            exportedFunctions: functions,
                            pipelineStages: library?.pipelineStages ?? ["prepare", "execute"]
                        )
                        onSave(new)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
