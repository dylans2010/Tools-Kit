/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Replaced manual stat pills and headers with native Section titles and LabeledContent.
 - Modernized dependency rows using a private struct DependencyGraphRow with semantic icons.
 - Standardized conflict alerts using semantic Label and monospaced typography.
 - strictly preserved all SDKRuntimeWorkspaceState dependency management and conflict resolution logic.
 - Improved visual hierarchy for lazy loading status and hook indicators.
 - Implemented ContentUnavailableView for empty graph states.
 */

import SwiftUI

struct IDEDependenciesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    private let conflictResolver = SDKDependencyConflictResolver()

    var body: some View {
        List {
            Section("Execution Tree") {
                LabeledContent("Graph Nodes") {
                    Text("\(state.dependencies.count)").monospaced().bold().foregroundStyle(Color.accentColor)
                }
            }

            let conflicts = conflictResolver.conflicts(in: state.dependencies)
            if !conflicts.isEmpty {
                Section("Conflict Alerts") {
                    ForEach(conflicts, id: \.self) { conflict in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(conflict).font(.subheadline.bold())
                                Text(conflictResolver.suggestion(for: conflict)).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                    }
                }
            }

            Section("Project Graph") {
                if state.dependencies.isEmpty {
                    ContentUnavailableView(
                        "No Dependencies",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        description: Text("Register libraries or configure project nodes to build the graph.")
                    )
                } else {
                    ForEach(state.dependencies) { node in
                        DependencyGraphRow(node: node)
                    }
                    .onDelete(perform: deleteDependencies)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dependencies")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteDependencies(at offsets: IndexSet) {
        state.dependencies.remove(atOffsets: offsets)
        state.recalculateDiagnostics()
    }
}

// MARK: - Private Subviews

private struct DependencyGraphRow: View {
    let node: SDKDependencyNode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name).font(.headline)
                    Text(node.kind.rawValue.uppercased()).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("v\(node.version)").font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
            }

            if !node.requiredScopes.isEmpty {
                Text(node.requiredScopes.joined(separator: ", "))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                if node.lazyLoaded { Label("Lazy", systemImage: "clock.arrow.circlepath").font(.caption2) }
                if node.preRunHook != nil { Label("Hook", systemImage: "terminal").font(.caption2) }
                Spacer()
                Text("\(node.linkedTo.count) links").font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
