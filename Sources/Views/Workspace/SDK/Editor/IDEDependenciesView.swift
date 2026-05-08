import SwiftUI
import UniformTypeIdentifiers

struct IDEDependenciesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    private let conflictResolver = SDKDependencyConflictResolver()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dependency Graph").font(.headline)
                            Text("Orchestrate SDK module connections and execution ordering.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill("\(state.dependencies.count) NODES", systemImage: "point.3.connected.trianglepath.dotted", color: .blue)
                    }

                    Button {
                        state.resolveAllConflicts()
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Fix All Conflicts")
                        }
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Graph Manager", subtitle: "Managed SDK execution units", systemImage: "circle.grid.cross.fill")
            }

            Section {
                ForEach($state.dependencies) { $node in
                    dependencyNodeRow(node: $node)
                }
                .onDelete { offsets in
                    state.dependencies.remove(atOffsets: offsets)
                    state.recalculateDiagnostics()
                }

                Button {
                    state.dependencies.append(SDKDependencyNode(name: "Dependency \(state.dependencies.count + 1)", kind: .library))
                    state.recalculateDiagnostics()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Dependency Node")
                    }
                    .font(.subheadline.semibold())
                    .foregroundStyle(.accent)
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Nodes", subtitle: "Active system dependencies", alignment: .leading)
            }

            Section("Conflict Alerts") {
                let conflicts = conflictResolver.conflicts(in: state.dependencies)
                if conflicts.isEmpty {
                    Label("No conflicts detected", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(conflicts, id: \.self) { conflict in
                        VStack(alignment: .leading, spacing: 4) {
                            Label(conflict, systemImage: "exclamationmark.triangle.fill")
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
        }
        .navigationTitle("Dependencies")
        .onChange(of: state.dependencies) { _, _ in
            state.saveSnapshot()
        }
    }

    private func dependencyNodeRow(node: Binding<SDKDependencyNode>) -> some View {
        SDKModernCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: kindIcon(node.wrappedValue.kind))
                        .foregroundStyle(.secondary)
                    TextField("Name", text: node.name)
                        .font(.subheadline.bold())
                    Spacer()
                    Picker("", selection: node.kind) {
                        ForEach(SDKDependencyNode.Kind.allCases, id: \.self) { kind in
                            Text(kind.rawValue.capitalized).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                HStack {
                    Label {
                        TextField("Version", text: node.version)
                            .font(.system(size: 10, design: .monospaced))
                    } icon: {
                        Image(systemName: "tag.fill").font(.system(size: 10))
                    }
                    Spacer()
                    Toggle("Lazy Load", isOn: node.lazyLoaded)
                        .font(.caption2)
                        .toggleStyle(.switch)
                        .scaleEffect(0.8)
                }

                if node.wrappedValue.kind == .library {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Execution Hooks").font(.system(size: 8, weight: .bold)).foregroundStyle(.tertiary).textCase(.uppercase)
                        HStack {
                            TextField("Pre-run", text: Binding(get: { node.wrappedValue.preRunHook ?? "" }, set: { node.wrappedValue.preRunHook = $0.isEmpty ? nil : $0 }))
                            Divider().frame(height: 10)
                            TextField("Post-run", text: Binding(get: { node.wrappedValue.postRunHook ?? "" }, set: { node.wrappedValue.postRunHook = $0.isEmpty ? nil : $0 }))
                        }
                        .font(.system(size: 10, design: .monospaced))
                        .padding(6)
                        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
                    }
                }

                HStack {
                    Label("\(node.wrappedValue.linkedTo.count) Links", systemImage: "link")
                    Spacer()
                    if !node.wrappedValue.conditionalExpression.isEmpty {
                        Label("Conditional", systemImage: "questionmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .onDrag {
            NSItemProvider(object: node.wrappedValue.id.uuidString as NSString)
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
                    if !node.wrappedValue.linkedTo.contains(linkedID), linkedID != node.wrappedValue.id {
                        node.wrappedValue.linkedTo.append(linkedID)
                        state.recalculateDiagnostics()
                    }
                }
            }
            return true
        }
    }

    private func kindIcon(_ kind: SDKDependencyNode.Kind) -> String {
        switch kind {
        case .library: return "books.vertical.fill"
        case .connector: return "link.circle.fill"
        case .plugin: return "puzzlepiece.extension.fill"
        case .sdkApp: return "app.badge.fill"
        }
    }
}
