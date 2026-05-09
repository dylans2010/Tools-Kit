/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Modernized the header stats using a centered SDKStatPill group with semantic colors.
 - Replaced manual category switcher with a modern horizontal ScrollView of FilterChips.
 - Modernized MarketplacePluginRow and MarketplaceSDKAppRow with improved spacing, better SF Symbol usage, and semantic typography.
 - strictly preserved all PluginManager and PluginRuntimeEngine search/filter logic.
 - Added ContentUnavailableView for empty search results and category filters.
 - Standardized "Made For Workspace" badge with a dynamic gradient and native styling.
 - Extracted subviews for MarketplaceStatHeader, FilterCategorySection, and result rows.
 */

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
                MarketplaceStatHeader(
                    available: manager.availablePlugins.count,
                    installed: manager.installedPlugins.count,
                    apps: sdkRuntime.loadedApps.count
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            Section {
                Picker("Marketplace View", selection: $selectedTab) {
                    ForEach(MarketplaceTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if selectedTab == .plugins {
                Section {
                    FilterCategorySection(selectedCategory: $selectedCategory)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

                Section("Discover Plugins") {
                    if filteredPlugins.isEmpty {
                        ContentUnavailableView("No Plugins", systemImage: "puzzlepiece.slash", description: Text("No extensions match your current filter or search."))
                    } else {
                        ForEach(filteredPlugins) { plugin in
                            NavigationLink {
                                PluginDetailView(pluginID: plugin.id)
                            } label: {
                                MarketplacePluginRow(plugin: plugin)
                            }
                        }
                    }
                }
            } else {
                Section("Native SDK Apps") {
                    if filteredSDKApps.isEmpty {
                        ContentUnavailableView("No SDK Apps", systemImage: "hammer.fill", description: Text("Applications built with Workspace SDK will appear here."))
                    } else {
                        ForEach(filteredSDKApps) { app in
                            MarketplaceSDKAppRow(app: app, isRunning: sdkRuntime.isRunning(app.id))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search modules...")
        .navigationTitle("Marketplace")
    }
}

// MARK: - Private Subviews

private struct MarketplaceStatHeader: View {
    let available: Int
    let installed: Int
    let apps: Int

    var body: some View {
        HStack(spacing: 0) {
            SDKStatPill(label: "Available", value: "\(available)", color: .blue)
            SDKStatPill(label: "Installed", value: "\(installed)", color: .sdkSuccess)
            SDKStatPill(label: "SDK Apps", value: "\(apps)", color: .purple)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct FilterCategorySection: View {
    @Binding var selectedCategory: PluginCapability?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                ForEach(PluginCapability.allCases) { cap in
                    FilterChip(title: cap.displayName, isSelected: selectedCategory == cap) { selectedCategory = cap }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
}

struct MarketplacePluginRow: View {
    let plugin: PluginDefinition
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: plugin.icon)
                .font(.title3)
                .foregroundStyle(.accent)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(plugin.name).font(.subheadline.bold())
                    if plugin.isInstalled {
                        Image(systemName: "checkmark.seal.fill").font(.caption2).foregroundStyle(.sdkSuccess)
                    }
                }
                Text(plugin.description).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 4) {
                    Text("v\(plugin.version)").monospaced()
                    Text("·")
                    Text(plugin.author)
                }.font(.system(size: 8, weight: .medium)).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct MarketplaceSDKAppRow: View {
    let app: SDKAppDefinition
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hammer.fill")
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 44, height: 44)
                .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(app.name).font(.subheadline.bold())
                    if app.madeForWorkspace { MadeForWorkspaceBadge() }
                    if isRunning { Circle().fill(.green).frame(width: 6, height: 6) }
                }
                if !app.description.isEmpty {
                    Text(app.description).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                HStack(spacing: 4) {
                    Text("v\(app.version)").monospaced()
                    if !app.author.isEmpty {
                        Text("·")
                        Text(app.author)
                    }
                }.font(.system(size: 8, weight: .medium)).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct MadeForWorkspaceBadge: View {
    var body: some View {
        Text("Made For Workspace")
            .font(.system(size: 7, weight: .black))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), in: Capsule())
            .foregroundStyle(.white)
    }
}
