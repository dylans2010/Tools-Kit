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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SDK Libraries").font(.headline)
                        Text("Shared modules and pipeline stages.").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { editingLibrary = newLibrary() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                SDKSectionHeader("Module Registry", subtitle: "Managed SDK execution units", systemImage: "books.vertical.fill")
            }

            Section {
                if state.libraries.isEmpty {
                    ContentUnavailableView("No Libraries", systemImage: "books.vertical", description: Text("Add a library to start building SDK modules."))
                        .padding(.vertical, 20)
                } else {
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
            } header: {
                SDKSectionHeader("Linked Libraries", subtitle: "Active system modules", alignment: .leading)
            }

            Section {
                if let first = state.libraries.first {
                    SDKModernCard(padding: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(first.name, systemImage: "arrow.triangle.2.circlepath")
                                    .font(.subheadline.bold())
                                Spacer()
                                SDKStatusPill("Preferred", color: .blue)
                            }
                            Text(resolver.diff(from: first.version, to: resolver.resolvePreferredVersion(for: first.name, availableVersions: [first.version, "2.0.0"], preferredVersion: nil) ?? first.version))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Register libraries to enable version analysis.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                }
            } header: {
                SDKSectionHeader("Version Analysis", subtitle: "Dependency and update tracking", systemImage: "clock.arrow.circlepath")
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
        SDKModernCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(library.name).font(.subheadline.bold())
                        Text("v\(library.version)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                    }
                    Spacer()
                    SDKStatusPill(library.usageCount > 0 ? "Active" : "Idle", color: library.usageCount > 0 ? .sdkSuccess : .secondary)
                }

                HStack(spacing: 16) {
                    metric("Calls", "\(library.usageCount)", icon: "phone.fill")
                    metric("Scopes", "\(library.linkedScopes.count)", icon: "lock.shield.fill")
                    metric("Exports", "\(library.exportedFunctions.count)", icon: "shippingbox.fill")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pipeline Stages").font(.system(size: 8, weight: .bold)).foregroundStyle(.tertiary).textCase(.uppercase)
                    Text(library.pipelineStages.joined(separator: " → ").ifEmpty("No stages configured"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
    }

    private func metric(_ label: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8))
            Text("\(value) \(label)").font(.system(size: 9, weight: .semibold))
        }
        .foregroundStyle(.secondary)
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
