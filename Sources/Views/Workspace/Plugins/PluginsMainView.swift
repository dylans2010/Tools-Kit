import SwiftUI

struct PluginsMainView: View {
    @StateObject private var manager = PluginManager.shared
    @StateObject private var runtime = PluginRuntime.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                quickActionsSection
                activePluginsSection
                recentActivitySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Plugins Hub")
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workspace OS Extensions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("System Plugins")
                    .font(.title2.bold())
            }
            Spacer()
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
        }
    }

    private var quickActionsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            NavigationLink(destination: PluginBuildView()) {
                quickActionCard(title: "Create Plugin", icon: "plus.app.fill", color: .blue)
            }
            NavigationLink(destination: PluginsInstalledView()) {
                quickActionCard(title: "Installed", icon: "square.grid.2x2.fill", color: .green)
            }
            NavigationLink(destination: PluginMarketplaceView()) {
                quickActionCard(title: "Marketplace", icon: "cart.fill", color: .orange)
            }
            NavigationLink(destination: PluginDevConsoleView()) {
                quickActionCard(title: "Debug Console", icon: "terminal.fill", color: .purple)
            }
        }
    }

    private func quickActionCard(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var activePluginsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Plugins")
                .font(.headline)

            if manager.installedPlugins.filter({ $0.isEnabled }).isEmpty {
                Text("No active plugins.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4])))
            } else {
                ForEach(manager.installedPlugins.filter({ $0.isEnabled })) { plugin in
                    HStack {
                        Image(systemName: plugin.icon)
                            .foregroundColor(.blue)
                        Text(plugin.name)
                        Spacer()
                        Text("v\(plugin.version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Feed")
                .font(.headline)

            if runtime.logs.isEmpty {
                Text("No recent activity.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(runtime.logs.prefix(5)) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(manager.installedPlugins.first(where: { $0.id == log.pluginID })?.name ?? "Unknown")
                                .font(.subheadline.bold())
                            Spacer()
                            Text(log.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text(log.output)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
                }
            }
        }
    }
}

struct PluginsInstalledView: View {
    @StateObject private var manager = PluginManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            if manager.installedPlugins.isEmpty {
                ContentUnavailableView("No Plugins", systemImage: "puzzlepiece.extension", description: Text("Install plugins from the marketplace or create your own."))
            } else {
                ForEach(manager.installedPlugins) { plugin in
                    NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                        HStack(spacing: 12) {
                            Image(systemName: plugin.icon)
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(plugin.name)
                                    .font(.headline)
                                Text(plugin.identifier)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { plugin.isEnabled },
                                set: { _ in manager.togglePlugin(plugin.id) }
                            ))
                            .labelsHidden()
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            manager.uninstall(pluginID: plugin.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Installed Plugins")
    }
}
