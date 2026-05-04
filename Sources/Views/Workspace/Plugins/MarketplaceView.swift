import SwiftUI

struct MarketplaceView: View {
    @StateObject private var manager = PluginManager.shared

    var body: some View {
        List {
            ForEach(manager.availablePlugins) { plugin in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plugin.name)
                            .font(.headline)
                        Text(plugin.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if plugin.isInstalled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Install") {
                            manager.install(pluginID: plugin.id)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Marketplace")
    }
}
