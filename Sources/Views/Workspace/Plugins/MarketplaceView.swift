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
                SDKModernCard(padding: 12) {
                    HStack(spacing: 0) {
                        SDKStatPill(label: "Available", value: "\(manager.availablePlugins.count)", color: .blue)
                        SDKStatPill(label: "Installed", value: "\(manager.installedPlugins.count)", color: .sdkSuccess)
                        SDKStatPill(label: "SDK Apps", value: "\(sdkRuntime.loadedApps.count)", color: .purple)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section {
                Picker("View", selection: $selectedTab) {
                    ForEach(MarketplaceTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                SDKSectionHeader("Repository", subtitle: "Select module type", alignment: .leading)
            }

            if selectedTab == .plugins {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }

                            ForEach(PluginCapability.allCases) { cap in
                                FilterChip(title: cap.displayName, isSelected: selectedCategory == cap) {
                                    selectedCategory = cap
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } header: {
                    SDKSectionHeader("Categories", subtitle: "Filter by capability", alignment: .leading)
                }

                Section {
                    if filteredPlugins.isEmpty {
                        ContentUnavailableView("No Plugins", systemImage: "magnifyingglass", description: Text("No plugins match your search or filter."))
                    } else {
                        ForEach(filteredPlugins) { plugin in
                            NavigationLink(destination: PluginDetailView(pluginID: plugin.id)) {
                                MarketplacePluginRow(plugin: plugin)
                            }
                        }
                    }
                } header: {
                    SDKSectionHeader("Discover Plugins", subtitle: "Verified community extensions", alignment: .leading)
                }
            } else {
                Section {
                    if filteredSDKApps.isEmpty {
                        ContentUnavailableView("No SDK Apps", systemImage: "hammer.fill", description: Text("Applications built with WorkspaceSDK will appear here."))
                    } else {
                        ForEach(filteredSDKApps) { app in
                            MarketplaceSDKAppRow(app: app, isRunning: sdkRuntime.isRunning(app.id))
                        }
                    }
                } header: {
                    SDKSectionHeader("Native Apps", subtitle: "SDK-powered applications", alignment: .leading)
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
