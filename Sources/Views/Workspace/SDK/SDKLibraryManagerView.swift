import SwiftUI

struct SDKLibraryManagerView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    private let resolver = SDKLibraryVersionResolver()

    var body: some View {
        List {
            Section("Libraries") {
                ForEach($state.libraries) { $library in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Library", text: $library.name)
                            .font(.headline)
                        HStack {
                            TextField("Version", text: $library.version)
                            Spacer()
                            Text("Calls: \(library.usageCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("Dependencies: \(library.dependencies.joined(separator: ", ").ifEmpty("None"))")
                            .font(.caption)
                        Text("Exports: \(library.exportedFunctions.map(\.name).joined(separator: ", ").ifEmpty("None"))")
                            .font(.caption)
                        Text("Pipeline: \(library.pipelineStages.joined(separator: " → ").ifEmpty("Not configured"))")
                            .font(.caption)

                        let preferred = resolver.resolvePreferredVersion(for: library.name, availableVersions: [library.version, "1.0.0", "1.1.0", "2.0.0"], preferredVersion: library.version) ?? library.version
                        Text("Compatibility: preferred runtime version \(preferred)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
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

            Section {
                Button {
                    state.libraries.append(
                        SDKLibraryDefinition(
                            name: "Library \(state.libraries.count + 1)",
                            linkedScopes: ["workspace.files.read"],
                            exportedFunctions: [SDKLibraryFunctionExport(name: "run", signature: "() -> Void")],
                            pipelineStages: ["prepare", "execute", "publish"]
                        )
                    )
                    state.recalculateDiagnostics()
                } label: {
                    Label("Add Library", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Libraries")
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
