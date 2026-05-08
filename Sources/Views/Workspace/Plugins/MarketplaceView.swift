import SwiftUI

struct MarketplaceView: View {
    @StateObject private var manager = PluginManager.shared
    @StateObject private var sdkRuntime = PluginRuntimeEngine.shared
    @State private var searchText = ""
    @State private var selectedCategory: PluginCapability?
    @State private var selectedTab: MarketplaceTab = .plugins

    enum MarketplaceTab: String, CaseIterable {
        case plugins = "Plugins"
        case projects = "Projects"
    }

    private var filteredPlugins: [PluginDefinition] {
        manager.availablePlugins.filter { plugin in
            let matchesSearch = searchText.isEmpty ||
                               plugin.name.localizedCaseInsensitiveContains(searchText) ||
                               plugin.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil ||
                                 plugin.capabilities.contains(selectedCategory!)
            return matchesSearch && matchesCategory
        }
    }

    private var filteredSDKApps: [SDKAppDefinition] {
        sdkRuntime.loadedApps.filter { app in
            searchText.isEmpty ||
            app.name.localizedCaseInsensitiveContains(searchText) ||
            app.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 20) {
                    StatusIndicator(label: "Available", count: manager.availablePlugins.count, color: .blue)
                    StatusIndicator(label: "Installed", count: manager.installedPlugins.count, color: .green)
                    StatusIndicator(label: "SDK Apps", count: sdkRuntime.loadedApps.count, color: .purple)
                }
                .padding(.vertical, 8)
            }

            Section {
                Picker("View", selection: $selectedTab) {
                    ForEach(MarketplaceTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            }

            if selectedTab == .plugins {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }

                            ForEach(PluginCapability.allCases) { cap in
                                FilterChip(title: cap.displayName, isSelected: selectedCategory == cap) {
                                    selectedCategory = cap
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Categories")
                }

                Section {
                    if filteredPlugins.isEmpty {
                        Text("No Plugins Found").foregroundColor(.secondary).font(.subheadline)
                    } else {
                        ForEach(filteredPlugins) { plugin in
                            NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                                MarketplacePluginRow(plugin: plugin)
                            }
                        }
                    }
                } header: {
                    Text("Discover Plugins")
                }
            } else {
                Section {
                    if filteredSDKApps.isEmpty {
                        ContentUnavailableView("No SDK Apps", systemImage: "puzzlepiece.extension", description: Text("Apps built with WorkspaceSDK will appear here."))
                    } else {
                        ForEach(filteredSDKApps) { app in
                            MarketplaceSDKAppRow(app: app, isRunning: sdkRuntime.isRunning(app.id))
                        }
                    }
                } header: {
                    Text("SDK Projects & Apps")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Marketplace")
        .navigationTitle("Marketplace")
    }
}

struct MarketplacePluginRow: View {
    let plugin: PluginDefinition

    var body: some View {
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
        }
        .padding(.vertical, 4)
    }
}

struct MarketplaceSDKAppRow: View {
    let app: SDKAppDefinition
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hammer.fill")
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 44, height: 44)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(app.name).font(.subheadline).bold()
                    if app.madeForWorkspace {
                        MadeForWorkspaceBadge()
                    }
                    if isRunning {
                        Circle().fill(.green).frame(width: 6, height: 6)
                    }
                }
                if !app.description.isEmpty {
                    Text(app.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                HStack {
                    Text("v\(app.version)").font(.caption2).foregroundStyle(.tertiary)
                    if !app.author.isEmpty {
                        Text("·").font(.caption2).foregroundStyle(.tertiary)
                        Text(app.author).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// "Made For Workspace" badge — visually distinct, auto-detected via SDK metadata.
struct MadeForWorkspaceBadge: View {
    var body: some View {
        Text("Made For Workspace")
            .font(.system(size: 8, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
