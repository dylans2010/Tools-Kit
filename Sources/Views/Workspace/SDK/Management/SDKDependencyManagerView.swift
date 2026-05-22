

import SwiftUI
import UniformTypeIdentifiers

struct SDKDependencyManagerView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    private let conflictResolver = SDKDependencyConflictResolver()

    var body: some View {
        List {
            Section("Execution Tree") {
                if state.dependencies.isEmpty {
                    ContentUnavailableView("No Dependencies", systemImage: "point.3.connected.trianglepath.dotted", description: Text("Register nodes to build the execution graph."))
                } else {
                    ForEach($state.dependencies) { $node in
                        DependencyTreeNodeRow(node: $node)
                    }
                    .onDelete { offsets in
                        state.dependencies.remove(atOffsets: offsets)
                        state.recalculateDiagnostics()
                    }
                }

                Button {
                    state.dependencies.append(SDKDependencyNode(name: "New Node", kind: .library))
                    state.recalculateDiagnostics()
                } label: {
                    Label("Add Dependency Node", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                }
            }

            Section("Conflict Resolution") {
                let conflicts = conflictResolver.conflicts(in: state.dependencies)
                if conflicts.isEmpty {
                    Label("System Integrity Verified", systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(.green)
                } else {
                    ForEach(conflicts, id: \.self) { conflict in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(conflict).font(.caption.bold())
                                Text(conflictResolver.suggestion(for: conflict)).font(.caption2).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dependencies")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: state.dependencies) { _, _ in state.saveSnapshot() }
    }
}

// MARK: - Private Subviews

private struct DependencyTreeNodeRow: View {
    @Binding var node: SDKDependencyNode
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Node Name", text: $node.name).font(.headline)
                Spacer()
                Picker("", selection: $node.kind) {
                    ForEach(SDKDependencyNode.Kind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu).labelsHidden().controlSize(.mini)
            }

            HStack {
                TextField("v1.0.0", text: $node.version).font(.caption.monospaced()).frame(width: 80)
                Spacer()
                Toggle("Lazy", isOn: $node.lazyLoaded).font(.caption2).labelsHidden()
                Text("Lazy").font(.caption2).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Pre-run Hook", text: Binding(get: { node.preRunHook ?? "" }, set: { node.preRunHook = $0.isEmpty ? nil : $0 })).font(.system(size: 9, design: .monospaced))
                if node.linkedTo.count > 0 {
                    Label("\(node.linkedTo.count) Links", systemImage: "link").font(.system(size: 8)).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
        .onDrag { NSItemProvider(object: node.id.uuidString as NSString) }
        .onDrop(of: [UTType.text.identifier], isTargeted: nil) { providers in
            providers.first?.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                let text = (item as? Data).flatMap { String(data: $0, encoding: .utf8) } ?? (item as? String)
                guard let idText = text?.trimmingCharacters(in: .whitespacesAndNewlines), let linkedID = UUID(uuidString: idText) else { return }
                Task { @MainActor in if !node.linkedTo.contains(linkedID), linkedID != node.id { node.linkedTo.append(linkedID); state.recalculateDiagnostics() } }
            }
            return true
        }
    }
}
