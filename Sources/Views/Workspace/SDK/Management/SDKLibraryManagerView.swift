

import SwiftUI

struct SDKLibraryManagerView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var editingLibrary: SDKLibraryDefinition?
    private let resolver = SDKLibraryVersionResolver()

    var body: some View {
        List {
            Section("Module Registry") {
                if state.libraries.isEmpty {
                    ContentUnavailableView("No Libraries", systemImage: "books.vertical", description: Text("Register SDK modules to manage shared business logic."))
                } else {
                    ForEach(state.libraries) { library in
                        Button { editingLibrary = library } label: {
                            LibraryItemRow(library: library)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        state.libraries.remove(atOffsets: offsets)
                        state.recalculateDiagnostics()
                    }
                }

                Button { editingLibrary = newLibrary() } label: {
                    Label("Register New Library", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                }
            }

            Section("Lifecycle Analysis") {
                if let first = state.libraries.first {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(first.name, systemImage: "arrow.triangle.2.circlepath")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("PREFERRED")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 4).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                        Text(resolver.diff(from: first.version, to: "2.0.0"))
                            .font(.caption2.monospaced()).foregroundStyle(.secondary)
                    }
                } else {
                    Text("Add modules to enable version tracking.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Libraries")
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
        }
    }

    private func newLibrary() -> SDKLibraryDefinition {
        SDKLibraryDefinition(name: "", version: "1.0.0", linkedScopes: [], exportedFunctions: [], pipelineStages: ["prepare", "execute"])
    }
}

// MARK: - Private Subviews

private struct LibraryItemRow: View {
    let library: SDKLibraryDefinition
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(library.name.isEmpty ? "Untitled Library" : library.name).font(.headline)
                Spacer()
                Text("v\(library.version)").font(.caption.monospaced()).foregroundStyle(Color.accentColor)
            }
            HStack(spacing: 12) {
                Label("\(library.usageCount) calls", systemImage: "phone").font(.caption2)
                Label("\(library.linkedScopes.count) scopes", systemImage: "lock.shield").font(.caption2)
            }.foregroundStyle(.secondary)
            if !library.pipelineStages.isEmpty {
                Text(library.pipelineStages.joined(separator: " → "))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.tertiary).lineLimit(1).padding(4).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SDKLibraryEditorSheet: View {
    @State var library: SDKLibraryDefinition
    let onSave: (SDKLibraryDefinition) -> Void
    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $library.name)
                TextField("Version", text: $library.version)
            }
            Section("Bindings") {
                TextField("Scopes (comma-separated)", text: Binding(
                    get: { library.linkedScopes.joined(separator: ", ") },
                    set: { library.linkedScopes = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                )).font(.caption.monospaced())
            }
            Section {
                Button("Save Module") { onSave(library) }
                    .buttonStyle(.borderedProminent).disabled(library.name.isEmpty).frame(maxWidth: .infinity)
            }
        }
    }
}
