import SwiftUI

// MARK: - Plugin Marketplace

struct PluginMarketplaceView: View {
    @StateObject private var manager = PluginManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: PluginDefinition.PluginCategory?
    @State private var selectedPlugin: PluginDefinition?
    @State private var showingInstalled = false

    private var displayedPlugins: [PluginDefinition] {
        var plugins = manager.availablePlugins
        if let cat = selectedCategory { plugins = plugins.filter { $0.category == cat } }
        if !searchText.isEmpty {
            plugins = plugins.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        return plugins
    }

    var body: some View {
        List {
            // Header stats
            Section {
                HStack(spacing: 20) {
                    StatPill(value: "\(manager.availablePlugins.count)", label: "Available", color: .blue)
                    StatPill(value: "\(manager.installedPlugins.count)", label: "Installed", color: .green)
                    StatPill(value: "\(manager.installedPlugins.filter { $0.isEnabled }.count)", label: "Active", color: .orange)
                }
            }

            // Category filter
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                        ForEach(PluginDefinition.PluginCategory.allCases, id: \.self) { cat in
                            FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) { selectedCategory = cat }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Categories")
            }

            Section("Plugins (\(displayedPlugins.count))") {
                ForEach(displayedPlugins) { plugin in
                    PluginRow(plugin: plugin) { selectedPlugin = plugin }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search plugins…")
        .navigationTitle("Plugin Marketplace")
        .toolbar {
            Button(action: { showingInstalled = true }) {
                Label("Installed", systemImage: "square.grid.2x2.fill")
            }
        }
        .sheet(item: $selectedPlugin) { plugin in
            PluginDetailView(pluginID: plugin.id)
        }
        .sheet(isPresented: $showingInstalled) {
            InstalledPluginsView()
        }
    }
}

// MARK: - Plugin Row

struct PluginRow: View {
    let plugin: PluginDefinition
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: plugin.icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(plugin.name).font(.subheadline).bold()
                        if plugin.isInstalled {
                            Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(.green)
                        }
                    }
                    Text(plugin.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    HStack {
                        Text("v\(plugin.version)").font(.caption2).foregroundStyle(.tertiary)
                        Text("·").font(.caption2).foregroundStyle(.tertiary)
                        Text(plugin.author).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Plugin Detail

struct PluginDetailView: View {
    let pluginID: UUID
    @StateObject private var manager = PluginManager.shared
    @Environment(\.dismiss) var dismiss

    private var plugin: PluginDefinition? {
        manager.availablePlugins.first { $0.id == pluginID }
    }

    var body: some View {
        NavigationStack {
            if let plugin = plugin {
                List {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: plugin.icon)
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                                .frame(width: 60, height: 60)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plugin.name).font(.title3.bold())
                                Text("by \(plugin.author)").font(.caption).foregroundStyle(.secondary)
                                Text("v\(plugin.version)").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)

                        Text(plugin.description).font(.body).foregroundStyle(.secondary)
                    }

                    Section("Details") {
                        LabeledContent("Category", value: plugin.category.rawValue)
                        LabeledContent("Targets", value: plugin.targetSystems.map { $0.rawValue }.joined(separator: ", "))
                        if let installed = plugin.installedAt {
                            LabeledContent("Installed", value: installed.formatted(date: .abbreviated, time: .omitted))
                        }
                    }

                    Section("Commands") {
                        if plugin.commands.isEmpty {
                            Text("No commands registered.").foregroundStyle(.secondary).font(.caption)
                        } else {
                            ForEach(plugin.commands) { cmd in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("/\(cmd.keyword)").font(.caption.bold()).foregroundStyle(.blue)
                                    Text(cmd.description).font(.caption2).foregroundStyle(.secondary)
                                    if !cmd.parameters.isEmpty {
                                        Text("Params: \(cmd.parameters.joined(separator: ", "))").font(.caption2).foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }

                    Section {
                        if plugin.isInstalled {
                            Button(role: .destructive) {
                                manager.uninstall(pluginID: plugin.id)
                                dismiss()
                            } label: {
                                Label("Uninstall", systemImage: "trash")
                            }
                        } else {
                            Button {
                                manager.install(pluginID: plugin.id)
                                dismiss()
                            } label: {
                                Label("Install Plugin", systemImage: "plus.app.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .navigationTitle(plugin.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            } else {
                Text("Plugin not found.")
            }
        }
    }
}

// MARK: - Installed Plugins

struct InstalledPluginsView: View {
    @StateObject private var manager = PluginManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if manager.installedPlugins.isEmpty {
                    ContentUnavailableView(
                        "No Plugins Installed",
                        systemImage: "puzzlepiece.extension",
                        description: Text("Browse the marketplace to find and install plugins.")
                    )
                } else {
                    ForEach(manager.installedPlugins) { plugin in
                        HStack {
                            Image(systemName: plugin.icon)
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 36, height: 36)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(plugin.name).font(.subheadline).bold()
                                Text("v\(plugin.version) · \(plugin.category.rawValue)").font(.caption2).foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { plugin.isEnabled },
                                set: { _ in manager.toggle(pluginID: plugin.id) }
                            ))
                            .labelsHidden()
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
            .navigationTitle("Installed Plugins")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
