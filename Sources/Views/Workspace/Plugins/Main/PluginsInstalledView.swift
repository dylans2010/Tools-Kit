

import SwiftUI

struct PluginsInstalledView: View {
    @StateObject private var manager = SDKPluginManager.shared

    var body: some View {
        List {
            if manager.plugins.isEmpty {
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
                    ForEach(manager.plugins) { plugin in
                        PluginInstalledRow(plugin: plugin, manager: manager)
                    }
                } header: {
                    Text("Installed Extensions (\(manager.plugins.count))")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Installed")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PluginInstalledRow: View {
    let plugin: SDKPlugin
    @ObservedObject var manager: SDKPluginManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension") // TODO: icon unavailable on SDKPlugin
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name).font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text("v\(plugin.version)").monospaced()
                    Text("·")
                    Text("Unknown Author") // TODO: author unavailable on SDKPlugin
                }.font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { plugin.isEnabled },
                set: { _ in
                    if plugin.isEnabled {
                        manager.disable(id: plugin.id)
                    } else {
                        manager.enable(id: plugin.id)
                    }
                }
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
                manager.remove(id: plugin.id)
            } label: {
                Label("Uninstall", systemImage: "trash")
            }
        }
    }
}
