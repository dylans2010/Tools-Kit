

import SwiftUI

struct PluginsInstalledView: View {
    @StateObject private var manager = SDKPluginManager.shared

    var body: some View {
        List {
            if manager.installedPlugins.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Plugins Installed",
                        systemImage: "puzzlepiece.extension",
                        description: Text("Visit the Marketplace to discover and install new extensions for your workspace.")
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(manager.installedPlugins) { plugin in
                        PluginInstalledRow(plugin: plugin, manager: manager)
                    }
                } header: {
                    Text("Installed Extensions (\(manager.installedPlugins.count))")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Installed")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PluginInstalledRow: View {
    let plugin: PluginDefinition
    @ObservedObject var manager: SDKPluginManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: plugin.icon)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name).font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text("v\(plugin.version)").monospaced()
                    Text("·")
                    Text(plugin.author)
                }.font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { plugin.isEnabled },
                set: { _ in manager.toggle(pluginID: plugin.id) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { /* Prevent row tap from interfering with toggle */ }
        .overlay(
            NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                EmptyView()
            }
            .opacity(0)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                manager.uninstall(pluginID: plugin.id)
            } label: {
                Label("Uninstall", systemImage: "trash")
            }
        }
    }
}
