import SwiftUI

struct SDKLibraryManagerView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var editingLibrary: SDKLibraryDefinition?
    private let resolver = SDKLibraryVersionResolver()

    private var isCompact: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label("SDK Libraries", systemImage: "books.vertical.fill")
                        .font(.headline)
                    Spacer()
                    Button { editingLibrary = newLibrary() } label: { Label("Add", systemImage: "plus") }
                        .buttonStyle(.borderedProminent)
                }
                Text("Libraries are synchronized into dependency nodes and executed through SDKExecutionCoordinator.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Linked Libraries") {
                ForEach(state.libraries) { library in
                    Button { editingLibrary = library } label: {
                        libraryCard(library)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    state.libraries.remove(atOffsets: offsets)
                    state.recalculateDiagnostics()
                }
            }

            Section("Version Diff Viewer") {
                if let first = state.libraries.first {
                    Text(resolver.diff(from: first.version, to: resolver.resolvePreferredVersion(for: first.name, availableVersions: [first.version, "2.0.0"], preferredVersion: nil) ?? first.version))
                        .font(.caption)
                } else {
                    Text("Add libraries to compare versions")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(item: $editingLibrary) { library in
            NavigationStack {
                SDKLibraryEditorSheet(library: library) { updated in
                    state.upsertLibrary(updated)
                    editingLibrary = nil
                }
                .navigationTitle(library.name.isEmpty ? "New Library" : library.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { editingLibrary = nil } } }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .navigationTitle("Libraries")
    }

    private func libraryCard(_ library: SDKLibraryDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(library.name).font(.headline)
                Spacer()
                Text("v\(library.version)").font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            if isCompact {
                VStack(alignment: .leading, spacing: 3) {
                    metric("Calls", "\(library.usageCount)")
                    metric("Scopes", "\(library.linkedScopes.count)")
                    metric("Exports", "\(library.exportedFunctions.count)")
                    metric("Stages", "\(library.pipelineStages.count)")
                }
            } else {
                HStack {
                    metric("Calls", "\(library.usageCount)")
                    metric("Scopes", "\(library.linkedScopes.count)")
                    metric("Exports", "\(library.exportedFunctions.count)")
                    metric("Stages", "\(library.pipelineStages.count)")
                }
            }
            Text("Pipeline: \(library.pipelineStages.joined(separator: " → ").ifEmpty("Not configured"))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }

    private func metric(_ key: String, _ value: String) -> some View {
        Label("\(key): \(value)", systemImage: "circle.fill")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private func newLibrary() -> SDKLibraryDefinition {
        SDKLibraryDefinition(
            name: "Library \(state.libraries.count + 1)",
            linkedScopes: ["workspace.files.read"],
            exportedFunctions: [SDKLibraryFunctionExport(name: "run", signature: "() -> Void")],
            pipelineStages: ["prepare", "execute", "publish"]
        )
    }
}

private struct SDKLibraryEditorSheet: View {
    @State var library: SDKLibraryDefinition
    let onSave: (SDKLibraryDefinition) -> Void

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Library", text: $library.name)
                TextField("Version", text: $library.version)
            }
            Section("SDK Scope Bindings") {
                TextField("Linked scopes", text: arrayBinding(\.linkedScopes))
                    .font(.system(.caption, design: .monospaced))
                Text("Comma-separated scopes used by SDK validation and execution.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Section("Exports") {
                TextField("Exported function names", text: Binding(
                    get: { library.exportedFunctions.map(\.name).joined(separator: ", ") },
                    set: { names in
                        library.exportedFunctions = split(names).map { SDKLibraryFunctionExport(name: $0, signature: "() -> Void") }
                    }
                ))
            }
            Section("Pipeline") {
                TextField("Pipeline stages", text: arrayBinding(\.pipelineStages))
                TextField("Dependencies", text: arrayBinding(\.dependencies))
            }
            Section {
                Button("Save Library") { onSave(library) }
                    .buttonStyle(.borderedProminent)
                    .disabled(library.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func arrayBinding(_ keyPath: WritableKeyPath<SDKLibraryDefinition, [String]>) -> Binding<String> {
        Binding(
            get: { library[keyPath: keyPath].joined(separator: ", ") },
            set: { library[keyPath: keyPath] = split($0) }
        )
    }

    private func split(_ text: String) -> [String] {
        text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}
