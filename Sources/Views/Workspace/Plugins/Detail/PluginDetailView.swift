

import SwiftUI

struct PluginDetailView: View {
    let pluginID: UUID
    @StateObject private var manager = SDKPluginManager.shared
    @Environment(\.dismiss) var dismiss

    private var plugin: SDKPlugin? {
        manager.plugins.first { $0.id == pluginID }
    }

    var body: some View {
        Group {
            if let plugin = plugin {
                List {
                    Section { PluginProfileHeader(plugin: plugin) }

                    Section("Registry Details") {
                        LabeledContent("Identifier") { Text("com.toolskit.plugin").font(.caption.monospaced()) } // TODO: identifier unavailable on SDKPlugin
                        LabeledContent("Date Added", value: plugin.installedAt.formatted(date: .abbreviated, time: .omitted))
                        LabeledContent("Last Run", value: "Never") // TODO: lastExecutedAt unavailable on SDKPlugin
                        LabeledContent("System Errors", value: "0").foregroundStyle(Color.secondary) // TODO: errorCount unavailable on SDKPlugin
                    }

                    Section("Capabilities") {
                        ForEach(plugin.permissions, id: \.self) { perm in
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(perm.rawValue.capitalized).font(.subheadline.bold())
                                    Text("Permission granted").font(.caption2).foregroundStyle(.secondary)
                                }
                            } icon: { Image(systemName: "shield.fill").foregroundStyle(Color.accentColor) }
                        }
                    }

                    Section("Active Triggers") {
                        ForEach(plugin.automationHooks, id: \.self) { hook in
                            Label(hook, systemImage: "bolt.fill").font(.caption.bold()).foregroundStyle(.orange)
                        }
                    }

                    Section("Management") {
                        Toggle("Enable Module", isOn: Binding(
                            get: { plugin.isEnabled },
                            set: { _ in
                                if plugin.isEnabled {
                                    manager.disable(id: plugin.id)
                                } else {
                                    manager.enable(id: plugin.id)
                                }
                            }
                        ))
                        Button(role: .destructive) {
                            manager.remove(id: plugin.id)
                            dismiss()
                        } label: {
                            Label("Uninstall Extension", systemImage: "trash").frame(maxWidth: .infinity)
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
    let plugin: SDKPlugin
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "puzzlepiece.extension").font(.largeTitle).foregroundStyle(Color.accentColor).frame(width: 64, height: 64).background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14)) // TODO: icon unavailable on SDKPlugin
                VStack(alignment: .leading, spacing: 4) {
                    Text(plugin.name).font(.title3.bold())
                    Text("By Unknown Author").font(.subheadline).foregroundStyle(.secondary) // TODO: author unavailable on SDKPlugin
                    Text("Version \(plugin.version)").font(.caption2.bold()).foregroundStyle(.tertiary)
                }
            }
            Text("No Description Available").font(.body).foregroundStyle(.secondary) // TODO: description unavailable on SDKPlugin
        }.padding(.vertical, 8)
    }
}
