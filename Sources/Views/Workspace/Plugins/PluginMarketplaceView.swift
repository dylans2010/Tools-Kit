import SwiftUI

struct PluginMarketplaceView: View {
    @StateObject private var manager = PluginManager.shared
    @State private var searchText = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 20) {
                    StatPill(label: "Available", value: "\(manager.marketplacePlugins.count)", color: .blue)
                    StatPill(label: "Installed", value: "\(manager.installedPlugins.count)", color: .green)
                }
                .padding(.vertical, 8)
            }

            Section("Featured Plugins") {
                ForEach(manager.marketplacePlugins) { plugin in
                    PluginRow(plugin: plugin)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search marketplace...")
        .navigationTitle("Marketplace")
    }
}

struct PluginRow: View {
    let plugin: Plugin
    @StateObject private var manager = PluginManager.shared

    var isInstalled: Bool {
        manager.installedPlugins.contains(where: { $0.identifier == plugin.identifier })
    }

    var body: some View {
        NavigationLink(destination: PluginDetailView(pluginID: plugin.id, isFromMarketplace: true)) {
            HStack(spacing: 12) {
                Image(systemName: plugin.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(plugin.name).font(.subheadline).bold()
                        if isInstalled {
                            Image(systemName: "checkmark.seal.fill").font(.caption).foregroundColor(.green)
                        }
                    }
                    Text(plugin.description).font(.caption).foregroundColor(.secondary).lineLimit(2)
                    Text("by \(plugin.author)").font(.caption2).foregroundColor(.tertiary)
                }
            }
        }
    }
}

struct PluginDetailView: View {
    let pluginID: UUID
    var isFromMarketplace: Bool = false

    @StateObject private var manager = PluginManager.shared
    @Environment(\.dismiss) var dismiss

    private var plugin: Plugin? {
        if isFromMarketplace {
            return manager.marketplacePlugins.first { $0.id == pluginID }
        } else {
            return manager.installedPlugins.first { $0.id == pluginID }
        }
    }

    var body: some View {
        Group {
            if let plugin = plugin {
                List {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: plugin.icon)
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                                .frame(width: 60, height: 60)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plugin.name).font(.title3.bold())
                                Text("by \(plugin.author)").font(.caption).foregroundColor(.secondary)
                                Text("v\(plugin.version)").font(.caption2).foregroundColor(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)

                        Text(plugin.description).font(.body).foregroundColor(.secondary)
                    }

                    Section("Capabilities & Actions") {
                        HStack {
                            Text("Capabilities")
                            Spacer()
                            Text(plugin.capabilities.map { $0.rawValue }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Actions")
                            Spacer()
                            Text(plugin.actions.map { $0.rawValue }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !plugin.commands.isEmpty {
                        Section("Commands") {
                            ForEach(plugin.commands) { cmd in
                                VStack(alignment: .leading) {
                                    Text("/\(cmd.keyword)").font(.subheadline.bold()).foregroundColor(.blue)
                                    Text(cmd.description).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Section("Permissions") {
                        ForEach(Array(plugin.permissions)) { perm in
                            Label(perm.rawValue, systemImage: "lock.shield")
                                .font(.caption)
                        }
                    }

                    Section {
                        if isFromMarketplace {
                            let alreadyInstalled = manager.installedPlugins.contains(where: { $0.identifier == plugin.identifier })
                            if alreadyInstalled {
                                Text("Already Installed")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Button {
                                    manager.install(plugin: plugin)
                                    dismiss()
                                } label: {
                                    Label("Install Plugin", systemImage: "plus.app.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else {
                            Button(role: .destructive) {
                                manager.uninstall(pluginID: plugin.id)
                                dismiss()
                            } label: {
                                Label("Uninstall", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .navigationTitle(plugin.name)
            } else {
                Text("Plugin not found.")
            }
        }
    }
}
