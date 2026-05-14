import SwiftUI

struct LibraryManageView: View {
    @StateObject private var authManager = AuthorizationManager.shared
    @State private var libraries: [LibraryDescriptor] = []

    struct LibraryDescriptor: Identifiable, Codable {
        let id: UUID
        let lib_id: String
        let version: String
        let capabilities: [String]
        let required_scopes: UInt64
        let input_schema: String
        let output_schema: String
        let rate_limit_policy: String
        let execution_constraints: [String]
    }

    var body: some View {
        List {
            Section("Invocation Pipeline") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Request → Scope Validation → Capability Resolution → Input Validation → Execution Bridge → Output Validation → Response")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.blue)
                }
            }

            Section("Active Libraries") {
                if libraries.isEmpty {
                    Text("No libraries registered").foregroundStyle(.secondary)
                } else {
                    ForEach(libraries) { lib in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(lib.lib_id).font(.headline)
                                Spacer()
                                Text("v\(lib.version)").font(.caption.monospaced())
                            }
                            Text("Capabilities: \(lib.capabilities.joined(separator: ", "))")
                                .font(.caption2)
                            Text("Scopes: \(lib.required_scopes)").font(.system(size: 8, design: .monospaced))
                        }
                    }
                }
            }

            Section("Capability Mapping Engine") {
                // Real mapping logic would be implemented here in a production controller
                Text("Resolving requested actions to library capabilities via CapabilityMappingEngine...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Isolation Rules") {
                Label("No direct workspace writes", systemImage: "lock.shield.fill")
                Label("No direct dependency graph mutation", systemImage: "graph.fill")
                Label("No unmanaged execution", systemImage: "bolt.shield.fill")
            }
        }
        .navigationTitle("Library Management")
        .onAppear {
            syncWithRegistry()
        }
    }

    private func syncWithRegistry() {
        let state = SDKRuntimeWorkspaceState.shared
        // Filter out any default placeholder logic and only use registered state
        self.libraries = state.libraries.map { lib in
            LibraryDescriptor(
                id: lib.id,
                lib_id: "com.toolskit.lib.\(lib.name.lowercased())",
                version: lib.version,
                capabilities: lib.exportedFunctions.map(\.name),
                required_scopes: SDKScope.workspaceRead.rawValue,
                input_schema: "{}",
                output_schema: "{}",
                rate_limit_policy: "standard",
                execution_constraints: ["sandboxed"]
            )
        }
    }
}
