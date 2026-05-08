import SwiftUI

struct IDEDependenciesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    private let conflictResolver = SDKDependencyConflictResolver()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Execution Graph").font(.headline)
                            Text("Manage SDK dependencies and resolve version conflicts.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill("\(state.dependencies.count) NODES", systemImage: "point.3.connected.trianglepath.dotted", color: .orange)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Dependencies", subtitle: "Graph configuration", systemImage: "link")
            }

            let conflicts = conflictResolver.conflicts(in: state.dependencies)
            if !conflicts.isEmpty {
                Section("Conflicts") {
                    ForEach(conflicts, id: \.self) { conflict in
                        VStack(alignment: .leading, spacing: 4) {
                            Label(conflict, systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.orange)
                            Text(conflictResolver.suggestion(for: conflict))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Project Graph") {
                if state.dependencies.isEmpty {
                    ContentUnavailableView("No Dependencies", systemImage: "point.3.connected.trianglepath.dotted", description: Text("Synchronization from libraries or project config is required."))
                } else {
                    ForEach(state.dependencies) { node in
                        dependencyRow(for: node)
                    }
                    .onDelete(perform: deleteDependencies)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dependencies")
    }

    private func dependencyRow(for node: SDKDependencyNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name)
                        .font(.system(size: 15, weight: .bold))
                    Text(node.kind.rawValue.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("v\(node.version)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if !node.requiredScopes.isEmpty {
                Text("Scopes: \(node.requiredScopes.joined(separator: ", "))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack {
                if node.lazyLoaded {
                    Label("Lazy", systemImage: "clock.arrow.circlepath").font(.system(size: 10))
                }
                if node.preRunHook != nil {
                    Label("Hook", systemImage: "terminal").font(.system(size: 10))
                }
                Spacer()
                Text("\(node.linkedTo.count) links").font(.system(size: 10)).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteDependencies(at offsets: IndexSet) {
        state.dependencies.remove(atOffsets: offsets)
        state.recalculateDiagnostics()
    }
}
