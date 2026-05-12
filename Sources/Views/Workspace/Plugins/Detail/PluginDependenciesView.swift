import SwiftUI

struct PluginDependenciesView: View {
    let plugin: PluginDefinition
    @State private var dependencies: [PluginDependency] = []
    @State private var isLoading = true

    var body: some View {
        List {
            Section("Plugin Info") {
                LabeledContent("Name", value: plugin.name)
                LabeledContent("Version", value: plugin.version)
                LabeledContent("Dependencies", value: "\(dependencies.count)")
            }

            Section("Required Dependencies") {
                let required = dependencies.filter { $0.isRequired }
                if required.isEmpty && !isLoading {
                    Text("No required dependencies")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(required) { dep in
                        dependencyRow(dep)
                    }
                }
            }

            Section("Optional Dependencies") {
                let optional = dependencies.filter { !$0.isRequired }
                if optional.isEmpty && !isLoading {
                    Text("No optional dependencies")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(optional) { dep in
                        dependencyRow(dep)
                    }
                }
            }

            Section("Dependency Graph") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plugin.name)
                        .font(.headline)
                    ForEach(dependencies) { dep in
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                                .foregroundStyle(.secondary)
                            Text(dep.name)
                                .font(.subheadline)
                            Text(dep.versionRange)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: dep.isResolved ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundStyle(dep.isResolved ? .green : .red)
                        }
                        .padding(.leading, 16)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Dependencies")
        .task { await loadDependencies() }
    }

    private func dependencyRow(_ dep: PluginDependency) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dep.name)
                    .font(.subheadline)
                Text(dep.versionRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if dep.isResolved {
                Label("Resolved", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Label("Missing", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func loadDependencies() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        dependencies = [
            PluginDependency(name: "SDK Core", versionRange: ">= 2.0.0", isRequired: true, isResolved: true),
            PluginDependency(name: "Event Bus", versionRange: ">= 1.0.0", isRequired: true, isResolved: true),
            PluginDependency(name: "Security Manager", versionRange: ">= 1.5.0", isRequired: false, isResolved: true),
        ]
        isLoading = false
    }
}

private struct PluginDependency: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let versionRange: String
    let isRequired: Bool
    let isResolved: Bool
}
