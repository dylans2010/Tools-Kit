import SwiftUI
import UniformTypeIdentifiers

struct SDKDependencyManagerView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    private let conflictResolver = SDKDependencyConflictResolver()

    var body: some View {
        List {
            Section("Dependency Graph") {
                ForEach($state.dependencies) { $node in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            TextField("Name", text: $node.name)
                            Spacer()
                            Picker("Type", selection: $node.kind) {
                                ForEach(SDKDependencyNode.Kind.allCases, id: \.self) { kind in
                                    Text(kind.rawValue).tag(kind)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        HStack {
                            TextField("Version", text: $node.version)
                            Toggle("Lazy", isOn: $node.lazyLoaded)
                                .toggleStyle(.switch)
                        }

                        TextField("Conditional activation", text: $node.conditionalExpression)
                        TextField("Pre-run hook", text: Binding(
                            get: { node.preRunHook ?? "" },
                            set: { node.preRunHook = $0.isEmpty ? nil : $0 }
                        ))
                        TextField("Post-run hook", text: Binding(
                            get: { node.postRunHook ?? "" },
                            set: { node.postRunHook = $0.isEmpty ? nil : $0 }
                        ))

                        Text("Links: \(node.linkedTo.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .onDrag {
                        NSItemProvider(object: node.id.uuidString as NSString)
                    }
                    .onDrop(of: [UTType.text.identifier], isTargeted: nil) { providers in
                        providers.first?.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                            let extracted: String?
                            if let data = item as? Data {
                                extracted = String(data: data, encoding: .utf8)
                            } else {
                                extracted = item as? String
                            }
                            guard let text = extracted?.trimmingCharacters(in: .whitespacesAndNewlines),
                                  let linkedID = UUID(uuidString: text) else { return }
                            Task { @MainActor in
                                if !node.linkedTo.contains(linkedID), linkedID != node.id {
                                    node.linkedTo.append(linkedID)
                                    state.recalculateDiagnostics()
                                }
                            }
                        }
                        return true
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    state.dependencies.remove(atOffsets: offsets)
                    state.recalculateDiagnostics()
                }
            }

            Section("Conflict Alerts") {
                let conflicts = conflictResolver.conflicts(in: state.dependencies)
                if conflicts.isEmpty {
                    Text("No conflicts detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(conflicts, id: \.self) { conflict in
                        VStack(alignment: .leading, spacing: 2) {
                            Label(conflict, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(conflictResolver.suggestion(for: conflict))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    state.dependencies.append(SDKDependencyNode(name: "Dependency \(state.dependencies.count + 1)", kind: .library))
                    state.recalculateDiagnostics()
                } label: {
                    Label("Add Dependency Node", systemImage: "plus")
                }

                Button("Resolution Assistant") {
                    if let firstConflict = conflictResolver.conflicts(in: state.dependencies).first {
                        SDKLogStore.shared.log(conflictResolver.suggestion(for: firstConflict), source: "SDKDependencyManagerView", level: .warning)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .onChange(of: state.dependencies) { _, _ in
            state.saveSnapshot()
        }
        .navigationTitle("Dependencies")
    }
}
