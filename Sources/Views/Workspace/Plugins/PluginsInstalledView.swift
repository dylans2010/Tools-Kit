import SwiftUI

struct PluginsInstalledView: View {
    @StateObject private var manager = PluginManager.shared

    var body: some View {
        List {
            if manager.installedPlugins.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Plugins Installed")
                            .font(.headline)
                        Text("Visit the marketplace to discover new extensions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        NavigationLink(destination: MarketplaceView()) {
                            Text("Go to Marketplace")
                                .bold()
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                Section("Installed (\(manager.installedPlugins.count))") {
                    ForEach(manager.installedPlugins) { plugin in
                        NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                            HStack(spacing: 12) {
                                Image(systemName: plugin.icon)
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .frame(width: 36, height: 36)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plugin.name).font(.subheadline).bold()
                                    Text("v\(plugin.version) · \(plugin.author)").font(.caption2).foregroundColor(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { plugin.isEnabled },
                                    set: { _ in manager.toggle(pluginID: plugin.id) }
                                ))
                                .labelsHidden()
                                .onTapGesture { } // Prevent NavigationLink trigger
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                manager.uninstall(pluginID: plugin.id)
                            } label: {
                                Label("Uninstall", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Installed Plugins")
    }
}
