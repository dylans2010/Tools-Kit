import SwiftUI

struct SDKLibraryManagerView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var editingLibrary: SDKLibraryDefinition?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SDKSectionHeader(
                    title: "SDK Libraries",
                    subtext: "Reusable modules managed by SDKExecutionCoordinator."
                )

                SDKModernCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Modules").font(.subheadline.bold())
                            Text("\(state.libraries.count) linked libraries").sdkSubtext()
                        }
                        Spacer()
                        Button { editingLibrary = newLibrary() } label: {
                            Label("Add Library", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                SDKSectionHeader(title: "Linked Libraries", subtext: "Synchronized into the dependency graph.")

                VStack(spacing: 12) {
                    ForEach(state.libraries) { library in
                        Button { editingLibrary = library } label: {
                            libraryCard(library)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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

    private func libraryCard(_ library: SDKLibraryDefinition) -> some View {
        SDKModernCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(library.name).font(.subheadline.bold())
                        Text("v\(library.version)").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    Spacer()
                    SDKStatusPill(status: .info, text: "\(library.usageCount) CALLS")
                }

                Text("Pipeline: \(library.pipelineStages.joined(separator: " → ").ifEmpty("No Stages"))")
                    .sdkSubtext()

                HStack(spacing: 16) {
                    Label("\(library.linkedScopes.count)", systemImage: "lock.shield").font(.caption2)
                    Label("\(library.exportedFunctions.count)", systemImage: "bolt.fill").font(.caption2)
                    Spacer()
                }
                .foregroundStyle(.tertiary)
            }
        }
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
                TextField("Library Name", text: $library.name)
                TextField("Version", text: $library.version)
            }
            Section("SDK Scope Bindings") {
                TextField("Linked scopes (comma-separated)", text: arrayBinding(\.linkedScopes))
                    .font(.system(.caption, design: .monospaced))
                Text("Scopes required for library execution.").sdkSubtext()
            }
            Section("Exports") {
                TextField("Function names (comma-separated)", text: Binding(
                    get: { library.exportedFunctions.map(\.name).joined(separator: ", ") },
                    set: { names in
                        library.exportedFunctions = split(names).map { SDKLibraryFunctionExport(name: $0, signature: "() -> Void") }
                    }
                ))
            }
            Section("Pipeline & Dependencies") {
                TextField("Stages", text: arrayBinding(\.pipelineStages))
                TextField("Dependencies", text: arrayBinding(\.dependencies))
            }

            Button { onSave(library) } label: {
                Text("Save Library").frame(maxWidth: .infinity).bold()
            }
            .buttonStyle(.borderedProminent)
            .disabled(library.name.trimmingCharacters(in: .whitespaces).isEmpty)
            .listRowBackground(Color.clear)
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
