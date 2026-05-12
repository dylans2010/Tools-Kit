import SwiftUI

struct IDEDependenciesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    private let conflictResolver = SDKDependencyConflictResolver()
    @State private var selectedNodeID: UUID?
    @State private var resolutionState: ResolutionState = .idle

    enum ResolutionState: String, Sendable {
        case idle = "Idle"
        case resolving = "Resolving"
        case resolved = "Resolved"
        case failed = "Failed"
    }

    var body: some View {
        List {
            Section("Resolution") {
                LabeledContent("State", value: resolutionState.rawValue)
                LabeledContent("Nodes", value: "\(state.dependencies.count)")
                Button {
                    runResolution()
                } label: {
                    Label("Resolve Graph", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("Dependency Operations") {
                Button { installDependency() } label: {
                    Label("Install Node", systemImage: "plus")
                }
                Button { updateSelectedNode() } label: {
                    Label("Update Selected", systemImage: "square.and.arrow.down")
                }
                .disabled(selectedNodeID == nil)
                Button(role: .destructive) { removeSelectedNode() } label: {
                    Label("Remove Selected", systemImage: "trash")
                }
                .disabled(selectedNodeID == nil)
            }

            let conflicts = conflictResolver.conflicts(in: state.dependencies)
            if !conflicts.isEmpty {
                Section("Conflict Alerts") {
                    ForEach(conflicts, id: \.self) { conflict in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conflict).font(.subheadline)
                            Text(conflictResolver.suggestion(for: conflict))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Dependency Graph") {
                if state.dependencies.isEmpty {
                    ContentUnavailableView(
                        "No Dependencies",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        description: Text("Install dependencies to build graph relationships.")
                    )
                } else {
                    ForEach(state.dependencies) { node in
                        DependencyNodeRow(
                            node: node,
                            linkedNames: linkedNames(for: node),
                            isSelected: selectedNodeID == node.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { selectedNodeID = node.id }
                    }
                    .onDelete(perform: deleteDependencies)
                }
            }

            if let selected = state.dependencies.first(where: { $0.id == selectedNodeID }) {
                Section("Selected Node") {
                    LabeledContent("Name", value: selected.name)
                    LabeledContent("Kind", value: selected.kind.rawValue)
                    LabeledContent("Version", value: "v\(selected.version)")
                    LabeledContent("Lazy Loaded", value: selected.lazyLoaded ? "Yes" : "No")
                    if !selected.requiredScopes.isEmpty {
                        LabeledContent("Scopes", value: selected.requiredScopes.joined(separator: ", "))
                    }
                }
            }
        }
        .navigationTitle("Dependencies")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func linkedNames(for node: SDKDependencyNode) -> String {
        let names = state.dependencies
            .filter { node.linkedTo.contains($0.id) }
            .map(\.name)
        return names.isEmpty ? "None" : names.joined(separator: ", ")
    }

    private func deleteDependencies(at offsets: IndexSet) {
        state.dependencies.remove(atOffsets: offsets)
        state.recalculateDiagnostics()
    }

    private func installDependency() {
        let newNode = SDKDependencyNode(
            name: "Module\(state.dependencies.count + 1)",
            kind: .library,
            version: "1.0.0",
            linkedTo: state.dependencies.last.map { [$0.id] } ?? [],
            requiredScopes: ["workspace.files.read"],
            lazyLoaded: false
        )
        state.dependencies.append(newNode)
        selectedNodeID = newNode.id
        state.recalculateDiagnostics()
    }

    private func updateSelectedNode() {
        guard let selectedNodeID,
              let idx = state.dependencies.firstIndex(where: { $0.id == selectedNodeID }) else {
            return
        }
        state.dependencies[idx].version = bumpPatch(state.dependencies[idx].version)
        state.recalculateDiagnostics()
    }

    private func removeSelectedNode() {
        guard let selectedNodeID else { return }
        state.dependencies.removeAll { $0.id == selectedNodeID }
        state.dependencies = state.dependencies.map { node in
            var updated = node
            updated.linkedTo.removeAll { $0 == selectedNodeID }
            return updated
        }
        self.selectedNodeID = nil
        state.recalculateDiagnostics()
    }

    private func runResolution() {
        resolutionState = .resolving
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            resolutionState = state.dependencies.isEmpty ? .failed : .resolved
        }
    }

    private func bumpPatch(_ version: String) -> String {
        let parts = version.split(separator: ".").map { Int($0) ?? 0 }
        let major = parts.indices.contains(0) ? parts[0] : 1
        let minor = parts.indices.contains(1) ? parts[1] : 0
        let patch = (parts.indices.contains(2) ? parts[2] : 0) + 1
        return "\(major).\(minor).\(patch)"
    }
}

private struct DependencyNodeRow: View {
    let node: SDKDependencyNode
    let linkedNames: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(node.name, systemImage: icon)
                    .font(.subheadline.bold())
                Spacer()
                Text("v\(node.version)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Kind", value: node.kind.rawValue)
                .font(.caption)
            LabeledContent("Links", value: linkedNames)
                .font(.caption)

            if !node.requiredScopes.isEmpty {
                Text("Scopes: \(node.requiredScopes.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.08) : nil)
    }

    private var icon: String {
        switch node.kind {
        case .library: return "books.vertical"
        case .connector: return "link"
        case .plugin: return "puzzlepiece.extension"
        case .sdkApp: return "hammer"
        }
    }
}
