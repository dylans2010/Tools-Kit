import SwiftUI

struct PluginsInstalledView: View {
    @StateObject private var manager = PluginManager.shared

    var body: some View {
        List {
            if manager.installedPlugins.isEmpty {
                ContentUnavailableView("No Plugins Installed", systemImage: "puzzlepiece", description: Text("Visit the marketplace to discover new extensions."))
            } else {
                ForEach(manager.installedPlugins) { plugin in
                    PluginRow(plugin: plugin)
                }
            }
        }
        .navigationTitle("Installed")
    }
}

struct PluginRow: View {
    let plugin: PluginDefinition
    @StateObject private var manager = PluginManager.shared

    var body: some View {
        HStack {
            Image(systemName: plugin.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text(plugin.name)
                    .font(.headline)
                Text(plugin.version)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { plugin.isEnabled },
                set: { _ in manager.toggle(pluginID: plugin.id) }
            ))
            .labelsHidden()
        }
    }
}
