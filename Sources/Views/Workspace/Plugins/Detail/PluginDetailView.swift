import SwiftUI

struct PluginDetailView: View {
    let pluginID: UUID
    @StateObject private var manager = PluginManager.shared
    @Environment(\.dismiss) var dismiss

    private var plugin: PluginDefinition? {
        manager.installedPlugins.first { $0.id == pluginID } ??
        manager.availablePlugins.first { $0.id == pluginID }
    }

    var body: some View {
        Group {
            if let plugin = plugin {
                List {
                    headerSection(plugin)
                    detailsSection(plugin)
                    permissionsSection(plugin)
                    actionsSection(plugin)
                    controlsSection(plugin)
                }
                .navigationTitle(plugin.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Plugin not found").foregroundColor(.secondary)
            }
        }
    }

    private func headerSection(_ plugin: PluginDefinition) -> some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: plugin.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(plugin.name).font(.title3.bold())
                    Text("By \(plugin.author)").font(.caption).foregroundStyle(.secondary)
                    Text("Version \(plugin.version)").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)

            Text(plugin.description).font(.body).foregroundStyle(.secondary)
        }
    }

    private func detailsSection(_ plugin: PluginDefinition) -> some View {
        Section {
            LabeledContent("Identifier", value: plugin.identifier)
            if let installed = plugin.installedAt {
                LabeledContent("Installed", value: installed.formatted(date: .abbreviated, time: .omitted))
            }
            if let lastExec = plugin.lastExecutedAt {
                LabeledContent("Last Executed", value: lastExec.formatted(.relative(presentation: .named)))
            }
            LabeledContent("Error Count", value: "\(plugin.errorCount)")
        } header: {
            Text("Details")
        }
    }

    private func permissionsSection(_ plugin: PluginDefinition) -> some View {
        Section {
            ForEach(plugin.permissions) { permission in
                VStack(alignment: .leading, spacing: 2) {
                    Text(permission.capability.displayName).font(.caption.bold())
                    Text(permission.description).font(.caption2).foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Permissions")
        }
    }

    private func actionsSection(_ plugin: PluginDefinition) -> some View {
        Section {
            ForEach(plugin.actions) { action in
                Label(action.rawValue, systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        } header: {
            Text("Active Triggers")
        }
    }

    private func controlsSection(_ plugin: PluginDefinition) -> some View {
        Section {
            if plugin.isInstalled {
                Toggle("Enabled", isOn: Binding(
                    get: { plugin.isEnabled },
                    set: { _ in manager.toggle(pluginID: plugin.id) }
                ))

                Button(role: .destructive) {
                    manager.uninstall(pluginID: plugin.id)
                    dismiss()
                } label: {
                    Label("Uninstall Plugin", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
            } else {
                Button {
                    manager.install(pluginID: plugin.id)
                    dismiss()
                } label: {
                    Label("Install Plugin", systemImage: "plus.app.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
