

import SwiftUI

struct PluginDetailView: View {
    let pluginID: UUID
    @StateObject private var manager = PluginManager.shared
    @Environment(\.dismiss) var dismiss

    private var plugin: PluginDefinition? {
        manager.installedPlugins.first { $0.id == pluginID } ?? manager.availablePlugins.first { $0.id == pluginID }
    }

    var body: some View {
        Group {
            if let plugin = plugin {
                List {
                    Section { PluginProfileHeader(plugin: plugin) }

                    Section("Registry Details") {
                        LabeledContent("Identifier") { Text(plugin.identifier).font(.caption.monospaced()) }
                        if let installed = plugin.installedAt { LabeledContent("Date Added", value: installed.formatted(date: .abbreviated, time: .omitted)) }
                        if let lastExec = plugin.lastExecutedAt { LabeledContent("Last Run", value: lastExec.formatted(.relative(presentation: .named))) }
                        LabeledContent("System Errors", value: "\(plugin.errorCount)").foregroundStyle(plugin.errorCount > 0 ? Color.red : Color.secondary)
                    }

                    Section("Capabilities") {
                        ForEach(plugin.permissions) { perm in
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(perm.capability.displayName).font(.subheadline.bold())
                                    Text(perm.description).font(.caption2).foregroundStyle(.secondary)
                                }
                            } icon: { Image(systemName: perm.capability.icon).foregroundStyle(Color.accentColor) }
                        }
                    }

                    Section("Active Triggers") {
                        ForEach(plugin.actions) { action in
                            Label(action.rawValue, systemImage: "bolt.fill").font(.caption.bold()).foregroundStyle(.orange)
                        }
                    }

                    Section("Management") {
                        if plugin.isInstalled {
                            Toggle("Enable Module", isOn: Binding(get: { plugin.isEnabled }, set: { _ in manager.toggle(pluginID: plugin.id) }))
                            Button(role: .destructive) { manager.uninstall(pluginID: plugin.id); dismiss() } label: {
                                Label("Uninstall Extension", systemImage: "trash").frame(maxWidth: .infinity)
                            }
                        } else {
                            Button { manager.install(pluginID: plugin.id); dismiss() } label: {
                                Label("Install Extension", systemImage: "plus.app.fill").frame(maxWidth: .infinity).bold()
                            }.buttonStyle(.borderedProminent)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(plugin.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("Plugin Not Found", systemImage: "puzzlepiece.slash", description: Text("The requested extension could not be located."))
            }
        }
    }
}

// MARK: - Private Subviews

private struct PluginProfileHeader: View {
    let plugin: PluginDefinition
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: plugin.icon).font(.largeTitle).foregroundStyle(Color.accentColor).frame(width: 64, height: 64).background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(plugin.name).font(.title3.bold())
                    Text("by \(plugin.author)").font(.subheadline).foregroundStyle(.secondary)
                    Text("Version \(plugin.version)").font(.caption2.bold()).foregroundStyle(.tertiary)
                }
            }
            Text(plugin.description).font(.body).foregroundStyle(.secondary)
        }.padding(.vertical, 8)
    }
}
