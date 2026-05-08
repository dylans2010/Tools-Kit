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
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection(plugin)

                        SDKSectionHeader(title: "Status", subtext: "Real-time plugin runtime state.")
                        SDKModernCard {
                            HStack {
                                LabeledContent("Status", value: plugin.isEnabled ? "ENABLED" : "DISABLED")
                                Spacer()
                                SDKStatusPill(status: plugin.isEnabled ? .success : .info, text: plugin.isEnabled ? "ACTIVE" : "IDLE")
                            }
                        }

                        SDKSectionHeader(title: "Capabilities", subtext: "Permissions and triggers.")
                        SDKModernCard {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(plugin.permissions) { permission in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(permission.capability.displayName).font(.caption.bold())
                                        Text(permission.description).sdkSubtext()
                                    }
                                }
                                if !plugin.actions.isEmpty {
                                    Divider()
                                    ForEach(plugin.actions) { action in
                                        Label(action.rawValue, systemImage: "bolt.fill")
                                            .font(.caption).foregroundStyle(.orange)
                                    }
                                }
                            }
                        }

                        SDKSectionHeader(title: "Management", subtext: "Plugin lifecycle controls.")
                        SDKModernCard {
                            VStack(spacing: 16) {
                                if plugin.isInstalled {
                                    Toggle("Plugin Enabled", isOn: Binding(
                                        get: { plugin.isEnabled },
                                        set: { _ in manager.toggle(pluginID: plugin.id) }
                                    ))
                                    .font(.subheadline.bold())

                                    Divider()

                                    Button(role: .destructive) {
                                        manager.uninstall(pluginID: plugin.id)
                                        dismiss()
                                    } label: {
                                        Label("Uninstall Plugin", systemImage: "trash")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                } else {
                                    Button {
                                        manager.install(pluginID: plugin.id)
                                        dismiss()
                                    } label: {
                                        Label("Install Plugin", systemImage: "plus.app.fill")
                                            .frame(maxWidth: .infinity).bold()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(plugin.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("Plugin not found", systemImage: "puzzlepiece")
            }
        }
    }

    private func headerSection(_ plugin: PluginDefinition) -> some View {
        SDKModernCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: plugin.icon)
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(plugin.name).font(.title3.bold())
                        Text("By \(plugin.author)").sdkSubtext()
                    }
                }

                Text(plugin.description).font(.body).foregroundStyle(.secondary)

                Divider()

                HStack {
                    Text("v\(plugin.version)").font(.caption.monospaced()).foregroundStyle(.tertiary)
                    Spacer()
                    Text(plugin.identifier).font(.caption2.monospaced()).foregroundStyle(.tertiary)
                }
            }
        }
    }
}
