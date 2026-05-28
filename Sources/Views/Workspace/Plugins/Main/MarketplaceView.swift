

import SwiftUI

struct MarketplaceView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @StateObject private var sdkRuntime = PluginRuntimeEngine.shared
    @State private var searchText = ""
    @State private var selectedCategory: PluginCapability?
    @State private var selectedTab: MarketplaceTab = .plugins

    @State private var sortOrder: MarketplaceSortOrder = .nameAsc
    @State private var showingSortOptions = false
    @State private var showingPluginPreview: SDKPlugin?
    @State private var wishlistIDs: Set<UUID> = []
    @State private var recentSearches: [String] = []
    @State private var showingSearchHistory = false
    @State private var showingCollections = false
    @State private var selectedCollection: PluginCollection?
    @State private var collections: [PluginCollection] = PluginCollection.defaults
    @State private var showingNewCollectionSheet = false
    @State private var showingReportSheet = false
    @State private var reportTargetPlugin: SDKPlugin?
    @State private var showingComparisonSheet = false
    @State private var showingInstaller = false
    @State private var comparisonPlugins: [SDKPlugin] = []
    @State private var viewMode: MarketplaceViewMode = .list
    @State private var showFeaturedBanner = true
    @State private var selectedMarketCategory: PluginMarketCategory?
    @State private var showingAdvancedFilters = false
    @State private var filterMinVersion = ""
    @State private var filterLicense = ""
    @State private var filterEnabledOnly = false

    enum MarketplaceTab: String, CaseIterable {
        case plugins = "Plugins"
        case projects = "Projects"
        case collections = "Collections"
        case trending = "Trending"
    }

    enum MarketplaceSortOrder: String, CaseIterable {
        case nameAsc = "Name (A-Z)"
        case nameDesc = "Name (Z-A)"
        case newest = "Newest First"
        case oldest = "Oldest First"
        case enabled = "Enabled First"
    }

    enum MarketplaceViewMode: String, CaseIterable {
        case list = "List"
        case grid = "Grid"
        case compact = "Compact"
    }

    private var filteredPlugins: [SDKPlugin] {
        var result = manager.plugins.filter { plugin in
            let matchesSearch = searchText.isEmpty ||
                               plugin.name.localizedCaseInsensitiveContains(searchText)
            let matchesEnabled = !filterEnabledOnly || plugin.isEnabled
            return matchesSearch && matchesEnabled
        }

        if let collection = selectedCollection {
            result = result.filter { collection.pluginIDs.contains($0.id) }
        }

        switch sortOrder {
        case .nameAsc: result.sort { $0.name < $1.name }
        case .nameDesc: result.sort { $0.name > $1.name }
        case .newest: result.sort { $0.installedAt > $1.installedAt }
        case .oldest: result.sort { $0.installedAt < $1.installedAt }
        case .enabled: result.sort { $0.isEnabled && !$1.isEnabled }
        }

        return result
    }

    private var filteredSDKApps: [SDKAppDefinition] {
        sdkRuntime.loadedApps.filter { app in
            searchText.isEmpty ||
            app.name.localizedCaseInsensitiveContains(searchText) ||
            app.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var trendingPlugins: [SDKPlugin] {
        Array(manager.plugins.filter(\.isEnabled).prefix(5))
    }

    private var recentlyInstalledPlugins: [SDKPlugin] {
        Array(manager.plugins.sorted { $0.installedAt > $1.installedAt }.prefix(5))
    }

    var body: some View {
        List {
            Section {
                MarketplaceStatHeader(
                    available: manager.plugins.count,
                    installed: manager.plugins.count,
                    apps: sdkRuntime.loadedApps.count,
                    wishlisted: wishlistIDs.count,
                    collections: collections.count
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            if showFeaturedBanner {
                Section {
                    MarketplaceFeaturedBanner(onDismiss: { withAnimation { showFeaturedBanner = false } })
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

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

            switch selectedTab {
            case .plugins:
                pluginsTabContent
            case .projects:
                projectsTabContent
            case .collections:
                collectionsTabContent
            case .trending:
                trendingTabContent
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search Modules")
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty && !recentSearches.contains(newValue) {
                recentSearches.insert(newValue, at: 0)
                if recentSearches.count > 10 { recentSearches.removeLast() }
            }
        }
        .navigationTitle("Marketplace")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Sort By") {
                        ForEach(MarketplaceSortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                HStack {
                                    Text(order.rawValue)
                                    if sortOrder == order { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                    Section("View Mode") {
                        ForEach(MarketplaceViewMode.allCases, id: \.self) { mode in
                            Button {
                                viewMode = mode
                            } label: {
                                HStack {
                                    Text(mode.rawValue)
                                    if viewMode == mode { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                    Divider()
                    Button { showingAdvancedFilters = true } label: {
                        Label("Advanced Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Button { showingComparisonSheet = true } label: {
                        Label("Compare Plugins", systemImage: "rectangle.on.rectangle.angled")
                    }
                    Divider()
                    Button { showingInstaller = true } label: {
                        Label("Install .tkproj", systemImage: "plus.app")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $showingPluginPreview) { plugin in
            NavigationStack {
                MarketplacePluginPreviewSheet(plugin: plugin, isWishlisted: wishlistIDs.contains(plugin.id)) {
                    toggleWishlist(plugin.id)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAdvancedFilters) {
            NavigationStack {
                MarketplaceAdvancedFiltersSheet(
                    filterEnabledOnly: $filterEnabledOnly,
                    filterMinVersion: $filterMinVersion,
                    filterLicense: $filterLicense,
                    selectedMarketCategory: $selectedMarketCategory
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingComparisonSheet) {
            NavigationStack {
                MarketplaceComparisonSheet(plugins: manager.plugins, selected: $comparisonPlugins)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingNewCollectionSheet) {
            NavigationStack {
                NewCollectionSheet(collections: $collections, plugins: manager.plugins)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $reportTargetPlugin) { plugin in
            NavigationStack {
                MarketplaceReportSheet(pluginName: plugin.name)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingInstaller) {
            ProjectInstallerView()
                .presentationDetents([.medium])
        }
    }

    // MARK: - Plugins Tab

    @ViewBuilder
    private var pluginsTabContent: some View {
        Section {
            FilterCategorySection(selectedCategory: $selectedCategory)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)

        if !recentSearches.isEmpty && searchText.isEmpty {
            Section("Recent Searches") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recentSearches, id: \.self) { term in
                            Button {
                                searchText = term
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 9))
                                    Text(term).font(.caption2.bold())
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color(.tertiarySystemBackground), in: Capsule())
                            }
                        }
                        Button {
                            recentSearches.removeAll()
                        } label: {
                            Text("Clear").font(.caption2.bold()).foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }

        if !wishlistIDs.isEmpty {
            Section {
                DisclosureGroup {
                    ForEach(manager.plugins.filter { wishlistIDs.contains($0.id) }) { plugin in
                        NavigationLink {
                            PluginDetailView(pluginID: plugin.id)
                        } label: {
                            MarketplacePluginRow(plugin: plugin, isWishlisted: true) {
                                toggleWishlist(plugin.id)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "heart.fill").foregroundStyle(.pink)
                        Text("Wishlist (\(wishlistIDs.count))").font(.subheadline.bold())
                    }
                }
            }
        }

        Section("Discover Plugins") {
            if filteredPlugins.isEmpty {
                ContentUnavailableView("No Plugins", systemImage: "puzzlepiece.slash", description: Text("No extensions match your current filter or search."))
            } else {
                switch viewMode {
                case .list:
                    ForEach(filteredPlugins) { plugin in
                        pluginRow(plugin)
                    }
                case .grid:
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                        ForEach(filteredPlugins) { plugin in
                            MarketplacePluginCard(plugin: plugin, isWishlisted: wishlistIDs.contains(plugin.id)) {
                                toggleWishlist(plugin.id)
                            } onPreview: {
                                showingPluginPreview = plugin
                            }
                        }
                    }
                    .padding(.vertical, 4)
                case .compact:
                    ForEach(filteredPlugins) { plugin in
                        MarketplaceCompactRow(plugin: plugin)
                    }
                }
            }
        }
    }

    // MARK: - Projects Tab

    @ViewBuilder
    private var projectsTabContent: some View {
        Section("Native SDK Apps") {
            if filteredSDKApps.isEmpty {
                ContentUnavailableView("No SDK Apps", systemImage: "hammer.fill", description: Text("Applications built with Workspace SDK will appear here."))
            } else {
                ForEach(filteredSDKApps) { app in
                    MarketplaceSDKAppRow(app: app, isRunning: sdkRuntime.isRunning(app.id))
                }
            }
        }

        Section("SDK App Statistics") {
            HStack(spacing: 16) {
                MarketplaceMiniStat(label: "Running", value: "\(sdkRuntime.loadedApps.filter { sdkRuntime.isRunning($0.id) }.count)", icon: "play.circle.fill", color: .green)
                MarketplaceMiniStat(label: "Stopped", value: "\(sdkRuntime.loadedApps.filter { !sdkRuntime.isRunning($0.id) }.count)", icon: "stop.circle.fill", color: .secondary)
                MarketplaceMiniStat(label: "Total", value: "\(sdkRuntime.loadedApps.count)", icon: "square.stack.fill", color: .blue)
            }
        }
    }

    // MARK: - Collections Tab

    @ViewBuilder
    private var collectionsTabContent: some View {
        Section {
            if collections.isEmpty {
                ContentUnavailableView("No Collections", systemImage: "folder", description: Text("Create collections to organize your favorite plugins."))
                    .scaleEffect(0.8)
            } else {
                ForEach(collections) { collection in
                    HStack {
                        Image(systemName: collection.icon)
                            .foregroundStyle(collection.color)
                            .frame(width: 36, height: 36)
                            .background(collection.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(collection.name).font(.subheadline.bold())
                            Text("\(collection.pluginIDs.count) plugin(s)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            selectedCollection = collection
                            selectedTab = .plugins
                        } label: {
                            Text("View").font(.caption.bold())
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { collections.remove(atOffsets: $0) }
            }

            Button {
                showingNewCollectionSheet = true
            } label: {
                Label("Create Collection", systemImage: "plus.circle.fill").font(.subheadline.bold())
            }
        } header: {
            Label("Plugin Collections", systemImage: "folder.fill")
        }
    }

    // MARK: - Trending Tab

    @ViewBuilder
    private var trendingTabContent: some View {
        Section {
            MarketplacePluginOfTheWeek(plugin: manager.plugins.first)
        } header: {
            Label("Plugin of the Week", systemImage: "star.circle.fill")
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)

        Section("Trending Plugins") {
            if trendingPlugins.isEmpty {
                Text("No trending plugins yet.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(trendingPlugins.enumerated()), id: \.element.id) { index, plugin in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 36)
                        MarketplacePluginRow(plugin: plugin, isWishlisted: wishlistIDs.contains(plugin.id)) {
                            toggleWishlist(plugin.id)
                        }
                    }
                }
            }
        }

        Section("Recently Added") {
            ForEach(recentlyInstalledPlugins) { plugin in
                NavigationLink {
                    PluginDetailView(pluginID: plugin.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plugin.name).font(.subheadline.bold())
                            Text(plugin.installedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }

        Section("Staff Picks") {
            if manager.plugins.isEmpty {
                Text("No staff picks available.").font(.caption).foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(manager.plugins.prefix(4)) { plugin in
                            MarketplaceStaffPickCard(plugin: plugin)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

        Section("Marketplace Announcements") {
            MarketplaceAnnouncementBanner(
                title: "Plugin SDK 2.0 Released",
                message: "Build more powerful plugins with the new SDK. Includes webhook support, scheduling, and feature flags.",
                icon: "megaphone.fill",
                color: .blue
            )
            MarketplaceAnnouncementBanner(
                title: "Security Update",
                message: "All plugins now support AES-256-GCM encryption and HMAC webhook signatures.",
                icon: "shield.checkered",
                color: .green
            )
        }
    }

    // MARK: - Helpers

    private func pluginRow(_ plugin: SDKPlugin) -> some View {
        NavigationLink {
            PluginDetailView(pluginID: plugin.id)
        } label: {
            MarketplacePluginRow(plugin: plugin, isWishlisted: wishlistIDs.contains(plugin.id)) {
                toggleWishlist(plugin.id)
            }
        }
        .swipeActions(edge: .trailing) {
            Button { toggleWishlist(plugin.id) } label: {
                Label(wishlistIDs.contains(plugin.id) ? "Unwishlist" : "Wishlist", systemImage: wishlistIDs.contains(plugin.id) ? "heart.slash" : "heart")
            }
            .tint(.pink)

            Button { showingPluginPreview = plugin } label: {
                Label("Preview", systemImage: "eye")
            }
            .tint(.blue)

            Button {
                reportTargetPlugin = plugin
            } label: {
                Label("Report", systemImage: "flag")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading) {
            Button {
                if comparisonPlugins.count < 3 {
                    comparisonPlugins.append(plugin)
                }
            } label: {
                Label("Compare", systemImage: "rectangle.on.rectangle")
            }
            .tint(.purple)
        }
    }

    private func toggleWishlist(_ id: UUID) {
        if wishlistIDs.contains(id) {
            wishlistIDs.remove(id)
        } else {
            wishlistIDs.insert(id)
        }
    }
}

// MARK: - Private Subviews

private struct MarketplaceStatHeader: View {
    let available: Int
    let installed: Int
    let apps: Int
    let wishlisted: Int
    let collections: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                SDKStatPill(label: "Available", value: "\(available)", color: .blue)
                SDKStatPill(label: "Installed", value: "\(installed)", color: .sdkSuccess)
                SDKStatPill(label: "SDK Apps", value: "\(apps)", color: .purple)
            }
            HStack(spacing: 0) {
                SDKStatPill(label: "Wishlisted", value: "\(wishlisted)", color: .pink)
                SDKStatPill(label: "Collections", value: "\(collections)", color: .orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct MarketplaceFeaturedBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Explore the Marketplace").font(.headline.bold())
                    Text("Discover powerful plugins to supercharge your workspace")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                MarketplaceQuickStat(icon: "puzzlepiece.fill", label: "Extensions", color: .blue)
                MarketplaceQuickStat(icon: "hammer.fill", label: "SDK Apps", color: .purple)
                MarketplaceQuickStat(icon: "shield.fill", label: "Verified", color: .green)
                MarketplaceQuickStat(icon: "bolt.fill", label: "Trending", color: .orange)
            }
        }
        .padding(16)
        .background(
            LinearGradient(colors: [.blue.opacity(0.08), .purple.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal, 16)
    }
}

private struct MarketplaceQuickStat: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
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
    let plugin: SDKPlugin
    var isWishlisted: Bool = false
    var onToggleWishlist: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(plugin.name).font(.subheadline.bold())
                    Image(systemName: "checkmark.seal.fill").font(.caption2).foregroundStyle(.sdkSuccess)
                    if plugin.isEnabled {
                        Text("Active")
                            .font(.system(size: 7, weight: .black))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.green.opacity(0.12), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }
                Text("No Description Available").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 4) {
                    Text("v\(plugin.version)").monospaced()
                    Text("·")
                    Text("Unknown Author")
                    Text("·")
                    Text(plugin.installedAt.formatted(date: .abbreviated, time: .omitted))
                }.font(.system(size: 8, weight: .medium)).foregroundStyle(.tertiary)
            }

            Spacer()

            if let onToggleWishlist {
                Button { onToggleWishlist() } label: {
                    Image(systemName: isWishlisted ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundStyle(isWishlisted ? .pink : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct MarketplaceCompactRow: View {
    let plugin: SDKPlugin

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(plugin.isEnabled ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)
            Text(plugin.name).font(.caption.bold())
            Spacer()
            Text("v\(plugin.version)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
        }
    }
}

private struct MarketplacePluginCard: View {
    let plugin: SDKPlugin
    let isWishlisted: Bool
    let onToggleWishlist: () -> Void
    let onPreview: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "puzzlepiece.extension")
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
                .frame(width: 60, height: 60)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))

            Text(plugin.name).font(.caption.bold()).lineLimit(1)
            Text("v\(plugin.version)").font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button { onPreview() } label: {
                    Image(systemName: "eye").font(.system(size: 10))
                }.buttonStyle(.plain)

                Button { onToggleWishlist() } label: {
                    Image(systemName: isWishlisted ? "heart.fill" : "heart")
                        .font(.system(size: 10))
                        .foregroundStyle(isWishlisted ? .pink : .secondary)
                }.buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
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
                    if isRunning {
                        HStack(spacing: 3) {
                            Circle().fill(.green).frame(width: 6, height: 6)
                            Text("Running").font(.system(size: 7, weight: .black)).foregroundStyle(.green)
                        }
                    }
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

private struct MarketplaceMiniStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(value).font(.caption.bold())
            Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MarketplacePluginOfTheWeek: View {
    let plugin: SDKPlugin?

    var body: some View {
        if let plugin {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                    Text("Featured Plugin").font(.caption.bold()).foregroundStyle(.yellow)
                }
                HStack(spacing: 12) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plugin.name).font(.headline.bold())
                        Text("v\(plugin.version)").font(.caption.monospaced()).foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(.yellow)
                            }
                            Text("5.0").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .padding(.horizontal, 16)
        } else {
            Text("No featured plugin this week.").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16)
        }
    }
}

private struct MarketplaceStaffPickCard: View {
    let plugin: SDKPlugin

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "puzzlepiece.extension")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.purple, in: RoundedRectangle(cornerRadius: 10))
            Text(plugin.name).font(.caption.bold()).lineLimit(1)
            Text("v\(plugin.version)").font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
            HStack(spacing: 2) {
                Image(systemName: "hand.thumbsup.fill").font(.system(size: 8)).foregroundStyle(.blue)
                Text("Staff Pick").font(.system(size: 7, weight: .black)).foregroundStyle(.blue)
            }
        }
        .padding(10)
        .frame(width: 120)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MarketplaceAnnouncementBanner: View {
    let title: String
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.bold())
                Text(message).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Plugin Preview Sheet

private struct MarketplacePluginPreviewSheet: View {
    let plugin: SDKPlugin
    let isWishlisted: Bool
    let onToggleWishlist: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 88, height: 88)
                    .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))

                VStack(spacing: 4) {
                    Text(plugin.name).font(.title2.bold())
                    Text("v\(plugin.version)").font(.caption.monospaced()).foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.caption)
                        Text("Verified").font(.caption.bold()).foregroundStyle(.green)
                    }
                }

                HStack(spacing: 16) {
                    PreviewStatColumn(label: "Permissions", value: "\(plugin.permissions.count)", icon: "lock.shield")
                    PreviewStatColumn(label: "Hooks", value: "\(plugin.automationHooks.count)", icon: "bolt")
                    PreviewStatColumn(label: "Tools", value: "\(plugin.tools.count)", icon: "wrench")
                    PreviewStatColumn(label: "Status", value: plugin.isEnabled ? "On" : "Off", icon: "power")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions").font(.headline.bold())
                    if plugin.permissions.isEmpty {
                        Text("No Permissions Required").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(plugin.permissions, id: \.self) { perm in
                            HStack {
                                Image(systemName: "checkmark.shield").foregroundStyle(.green).font(.caption)
                                Text(perm.rawValue.capitalized).font(.caption)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 12) {
                    Button { onToggleWishlist() } label: {
                        Label(isWishlisted ? "Wishlisted" : "Add to Wishlist", systemImage: isWishlisted ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity).bold()
                    }
                    .buttonStyle(.bordered)
                    .tint(isWishlisted ? .pink : .secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Plugin Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
    }
}

private struct PreviewStatColumn: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(.blue)
            Text(value).font(.caption.bold())
            Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Advanced Filters Sheet

private struct MarketplaceAdvancedFiltersSheet: View {
    @Binding var filterEnabledOnly: Bool
    @Binding var filterMinVersion: String
    @Binding var filterLicense: String
    @Binding var selectedMarketCategory: PluginMarketCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Status Filter") {
                Toggle(isOn: $filterEnabledOnly) {
                    Label("Enabled Only", systemImage: "checkmark.circle")
                }
            }

            Section("Version Filter") {
                TextField("Minimum Version (e.g. 1.0.0)", text: $filterMinVersion)
                    .font(.caption.monospaced())
            }

            Section("Category") {
                Picker("Market Category", selection: $selectedMarketCategory) {
                    Text("All").tag(PluginMarketCategory?.none)
                    ForEach(PluginMarketCategory.allCases) { cat in
                        Text(cat.rawValue).tag(PluginMarketCategory?.some(cat))
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                Button("Reset All Filters") {
                    filterEnabledOnly = false
                    filterMinVersion = ""
                    filterLicense = ""
                    selectedMarketCategory = nil
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Advanced Filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - Comparison Sheet

private struct MarketplaceComparisonSheet: View {
    let plugins: [SDKPlugin]
    @Binding var selected: [SDKPlugin]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Select Plugins to Compare (up to 3)") {
                ForEach(plugins) { plugin in
                    HStack {
                        let isSelected = selected.contains { $0.id == plugin.id }
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? .blue : .secondary)
                        Text(plugin.name).font(.subheadline.bold())
                        Spacer()
                        Text("v\(plugin.version)").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let idx = selected.firstIndex(where: { $0.id == plugin.id }) {
                            selected.remove(at: idx)
                        } else if selected.count < 3 {
                            selected.append(plugin)
                        }
                    }
                }
            }

            if selected.count >= 2 {
                Section("Comparison") {
                    HStack {
                        Text("Feature").font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(selected) { plugin in
                            Text(plugin.name).font(.caption.bold()).frame(maxWidth: .infinity)
                        }
                    }
                    ComparisonRow(label: "Version") { plugin in Text("v\(plugin.version)").font(.caption2.monospaced()) }
                    ComparisonRow(label: "Enabled") { plugin in Image(systemName: plugin.isEnabled ? "checkmark" : "xmark").foregroundStyle(plugin.isEnabled ? .green : .red).font(.caption) }
                    ComparisonRow(label: "Permissions") { plugin in Text("\(plugin.permissions.count)").font(.caption2) }
                    ComparisonRow(label: "Hooks") { plugin in Text("\(plugin.automationHooks.count)").font(.caption2) }
                    ComparisonRow(label: "Tools") { plugin in Text("\(plugin.tools.count)").font(.caption2) }
                }
            }
        }
        .navigationTitle("Compare Plugins")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Clear") { selected.removeAll() } }
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }

    @ViewBuilder
    private func ComparisonRow<Content: View>(label: String, @ViewBuilder content: @escaping (SDKPlugin) -> Content) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            ForEach(selected) { plugin in
                content(plugin).frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Report Sheet

private struct MarketplaceReportSheet: View {
    let pluginName: String
    @State private var reportReason: MarketplaceReportReason = .spam
    @State private var additionalDetails = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text("Report: \(pluginName)").font(.headline.bold())
            }

            Section("Reason") {
                Picker("Report Reason", selection: $reportReason) {
                    ForEach(MarketplaceReportReason.allCases, id: \.self) { reason in
                        Text(reason.rawValue).tag(reason)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Additional Details") {
                TextEditor(text: $additionalDetails)
                    .frame(minHeight: 80)
            }

            Section {
                Button("Submit Report") { dismiss() }
                    .frame(maxWidth: .infinity).bold()
                    .buttonStyle(.borderedProminent).tint(.red)
            }
        }
        .navigationTitle("Report Plugin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
        }
    }
}

// MARK: - New Collection Sheet

private struct NewCollectionSheet: View {
    @Binding var collections: [PluginCollection]
    let plugins: [SDKPlugin]
    @State private var name = ""
    @State private var icon = "folder.fill"
    @State private var selectedPluginIDs: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss

    private let iconOptions = ["folder.fill", "star.fill", "heart.fill", "bolt.fill", "flame.fill", "leaf.fill", "moon.fill", "sun.max.fill"]

    var body: some View {
        Form {
            Section("Collection Details") {
                TextField("Collection Name", text: $name)
                Picker("Icon", selection: $icon) {
                    ForEach(iconOptions, id: \.self) { ic in
                        Label(ic, systemImage: ic).tag(ic)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Select Plugins") {
                ForEach(plugins) { plugin in
                    HStack {
                        Image(systemName: selectedPluginIDs.contains(plugin.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedPluginIDs.contains(plugin.id) ? .blue : .secondary)
                        Text(plugin.name).font(.subheadline)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedPluginIDs.contains(plugin.id) {
                            selectedPluginIDs.remove(plugin.id)
                        } else {
                            selectedPluginIDs.insert(plugin.id)
                        }
                    }
                }
            }
        }
        .navigationTitle("New Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    collections.append(PluginCollection(name: name, icon: icon, pluginIDs: selectedPluginIDs))
                    dismiss()
                }
                .disabled(name.isEmpty).bold()
            }
        }
    }
}

// MARK: - Supporting Types

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

struct PluginCollection: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var color: Color = .blue
    var pluginIDs: Set<UUID>

    static var defaults: [PluginCollection] {
        [
            PluginCollection(name: "Favorites", icon: "star.fill", color: .yellow, pluginIDs: []),
            PluginCollection(name: "Productivity", icon: "bolt.fill", color: .orange, pluginIDs: []),
            PluginCollection(name: "Development", icon: "hammer.fill", color: .blue, pluginIDs: []),
        ]
    }
}

enum MarketplaceReportReason: String, CaseIterable {
    case spam = "Spam or Misleading"
    case malicious = "Malicious Content"
    case broken = "Broken or Non-Functional"
    case inappropriate = "Inappropriate Content"
    case copyright = "Copyright Violation"
    case privacy = "Privacy Concern"
    case other = "Other"
}
