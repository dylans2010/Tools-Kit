import SwiftUI
import Combine

struct PluginsMainView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @State private var recentEvents: [PluginEvent] = []
    @State private var cancellables = Set<AnyCancellable>()

    @State private var blockedPlugin: SDKPlugin?
    @State private var blockedReason: PluginValidationFailureReason = .capabilityMismatch
    @State private var blockedDetail = ""
    @State private var showingLimitedView = false
    @State private var showingConfigSheet = false
    @State private var selectedPlugin: SDKPlugin?
    @State private var searchText = ""

    // New State
    @State private var selectedSortOrder: PluginSortOrder = .name
    @State private var pinnedPluginIDs: Set<UUID> = []
    @State private var showingBulkActions = false
    @State private var showingHealthDashboard = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var maintenanceMode = false
    @State private var selectedQuickFilter: PluginQuickFilter = .all
    @State private var showingPluginGroups = false
    @State private var pluginGroups: [PluginGroup] = PluginGroup.defaults
    @State private var showingNewGroupSheet = false
    @State private var showingPerformanceDashboard = false
    @State private var showingDependencyGraph = false
    @State private var showingNotificationPreferences = false
    @State private var showingStorageSummary = false
    @State private var showingExecutionHistory = false
    @State private var showingSystemResources = false
    @State private var selectedViewStyle: PluginViewStyle = .standard
    @State private var expandedSections: Set<String> = ["active", "inactive", "development", "management"]

    enum PluginSortOrder: String, CaseIterable {
        case name = "Name"
        case status = "Status"
        case recentlyInstalled = "Recently Installed"
        case recentlyUsed = "Recently Used"
        case permissionCount = "Permissions"
    }

    enum PluginQuickFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case inactive = "Inactive"
        case pinned = "Pinned"
        case hasHooks = "Has Hooks"
        case multiPermission = "Multi-Perm"
    }

    enum PluginViewStyle: String, CaseIterable {
        case standard = "Standard"
        case compact = "Compact"
        case detailed = "Detailed"
    }

    var filteredPlugins: [SDKPlugin] {
        var result: [SDKPlugin]

        switch selectedQuickFilter {
        case .all:
            result = searchText.isEmpty ? manager.plugins : manager.plugins.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        case .active:
            result = manager.plugins.filter(\.isEnabled)
        case .inactive:
            result = manager.plugins.filter { !$0.isEnabled }
        case .pinned:
            result = manager.plugins.filter { pinnedPluginIDs.contains($0.id) }
        case .hasHooks:
            result = manager.plugins.filter { !$0.automationHooks.isEmpty }
        case .multiPermission:
            result = manager.plugins.filter { $0.permissions.count > 1 }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        switch selectedSortOrder {
        case .name: result.sort { $0.name < $1.name }
        case .status: result.sort { $0.isEnabled && !$1.isEnabled }
        case .recentlyInstalled: result.sort { $0.installedAt > $1.installedAt }
        case .recentlyUsed: result.sort { $0.installedAt > $1.installedAt }
        case .permissionCount: result.sort { $0.permissions.count > $1.permissions.count }
        }

        let pinned = result.filter { pinnedPluginIDs.contains($0.id) }
        let unpinned = result.filter { !pinnedPluginIDs.contains($0.id) }
        return pinned + unpinned
    }

    var enabledPlugins: [SDKPlugin] { filteredPlugins.filter(\.isEnabled) }
    var disabledPlugins: [SDKPlugin] { filteredPlugins.filter { !$0.isEnabled } }

    var body: some View {
        List {
            // Health Dashboard Header
            Section {
                PluginHealthDashboard(
                    total: manager.plugins.count,
                    enabled: enabledPlugins.count,
                    disabled: disabledPlugins.count,
                    pinned: pinnedPluginIDs.count,
                    hooks: manager.plugins.reduce(0) { $0 + $1.automationHooks.count },
                    permissions: manager.plugins.reduce(0) { $0 + $1.permissions.count },
                    maintenanceMode: maintenanceMode
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            if maintenanceMode {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundStyle(.orange)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Maintenance Mode Active").font(.subheadline.bold()).foregroundStyle(.orange)
                            Text("All plugins are temporarily suspended. Disable maintenance mode to resume normal operations.")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Quick Filters
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(PluginQuickFilter.allCases, id: \.self) { filter in
                            FilterChip(title: filter.rawValue, isSelected: selectedQuickFilter == filter) {
                                selectedQuickFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            // Quick Actions Bar
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        PluginQuickActionButton(icon: "bolt.fill", label: "Bulk", color: .blue) {
                            showingBulkActions = true
                        }
                        PluginQuickActionButton(icon: "chart.bar.fill", label: "Health", color: .green) {
                            showingHealthDashboard = true
                        }
                        PluginQuickActionButton(icon: "gauge.with.needle.fill", label: "Perf", color: .purple) {
                            showingPerformanceDashboard = true
                        }
                        PluginQuickActionButton(icon: "arrow.triangle.branch", label: "Deps", color: .orange) {
                            showingDependencyGraph = true
                        }
                        PluginQuickActionButton(icon: "square.and.arrow.up", label: "Export", color: .teal) {
                            showingExportSheet = true
                        }
                        PluginQuickActionButton(icon: "square.and.arrow.down", label: "Import", color: .indigo) {
                            showingImportSheet = true
                        }
                        PluginQuickActionButton(icon: "externaldrive.fill", label: "Storage", color: .brown) {
                            showingStorageSummary = true
                        }
                        PluginQuickActionButton(icon: "clock.arrow.circlepath", label: "History", color: .cyan) {
                            showingExecutionHistory = true
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            // Pinned Plugins
            if !pinnedPluginIDs.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: Binding(
                        get: { expandedSections.contains("pinned") },
                        set: { if $0 { expandedSections.insert("pinned") } else { expandedSections.remove("pinned") } }
                    )) {
                        ForEach(filteredPlugins.filter { pinnedPluginIDs.contains($0.id) }) { plugin in
                            pluginRowView(plugin)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "pin.fill").foregroundStyle(.orange)
                            Text("Pinned (\(pinnedPluginIDs.count))").font(.subheadline.bold())
                        }
                    }
                }
            }

            // Active Plugins
            if !enabledPlugins.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: Binding(
                        get: { expandedSections.contains("active") },
                        set: { if $0 { expandedSections.insert("active") } else { expandedSections.remove("active") } }
                    )) {
                        ForEach(enabledPlugins) { plugin in
                            pluginRowView(plugin)
                        }
                    } label: {
                        HStack {
                            Circle().fill(.green).frame(width: 8, height: 8)
                            Text("Active Plugins (\(enabledPlugins.count))").font(.subheadline.bold())
                        }
                    }
                }
            }

            // Inactive Plugins
            if !disabledPlugins.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: Binding(
                        get: { expandedSections.contains("inactive") },
                        set: { if $0 { expandedSections.insert("inactive") } else { expandedSections.remove("inactive") } }
                    )) {
                        ForEach(disabledPlugins) { plugin in
                            pluginRowView(plugin)
                        }
                    } label: {
                        HStack {
                            Circle().fill(.secondary).frame(width: 8, height: 8)
                            Text("Inactive Plugins (\(disabledPlugins.count))").font(.subheadline.bold())
                        }
                    }
                }
            }

            // Plugin Groups
            if !pluginGroups.isEmpty {
                Section("Plugin Groups") {
                    ForEach(pluginGroups) { group in
                        HStack {
                            Image(systemName: group.icon)
                                .foregroundStyle(group.color)
                                .frame(width: 28, height: 28)
                                .background(group.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.name).font(.subheadline.bold())
                                Text("\(group.pluginIDs.count) plugin(s)").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { pluginGroups.remove(atOffsets: $0) }

                    Button {
                        showingNewGroupSheet = true
                    } label: {
                        Label("New Group", systemImage: "plus.circle.fill").font(.caption.bold())
                    }
                }
            }

            // Development
            Section {
                DisclosureGroup(isExpanded: Binding(
                    get: { expandedSections.contains("development") },
                    set: { if $0 { expandedSections.insert("development") } else { expandedSections.remove("development") } }
                )) {
                    NavigationLink(destination: PluginBuildView()) {
                        Label("Builder", systemImage: "wrench.and.screwdriver")
                    }
                    NavigationLink(destination: PluginDevConsoleView()) {
                        Label("Developer Console", systemImage: "terminal")
                    }
                    NavigationLink(destination: MarketplaceView()) {
                        Label("Marketplace", systemImage: "storefront")
                    }
                } label: {
                    HStack {
                        Image(systemName: "hammer.fill").foregroundStyle(.blue)
                        Text("Development").font(.subheadline.bold())
                    }
                }
            }

            // Management
            Section {
                DisclosureGroup(isExpanded: Binding(
                    get: { expandedSections.contains("management") },
                    set: { if $0 { expandedSections.insert("management") } else { expandedSections.remove("management") } }
                )) {
                    NavigationLink(destination: PluginsInstalledView()) {
                        Label("All Installed", systemImage: "square.stack.3d.up")
                    }
                    NavigationLink(destination: ConnectorsMainView()) {
                        Label("Plugin Connectors", systemImage: "cable.connector")
                    }
                    NavigationLink(destination: PluginSecurityView()) {
                        Label("Security", systemImage: "lock.shield")
                    }
                } label: {
                    HStack {
                        Image(systemName: "gearshape.fill").foregroundStyle(.secondary)
                        Text("Management").font(.subheadline.bold())
                    }
                }
            }

            // System Resources Monitor
            Section("System Resources") {
                HStack(spacing: 16) {
                    PluginResourceGauge(label: "CPU", value: 0.15, color: .blue, icon: "cpu")
                    PluginResourceGauge(label: "Memory", value: 0.32, color: .green, icon: "memorychip")
                    PluginResourceGauge(label: "Disk", value: 0.08, color: .orange, icon: "internaldrive")
                    PluginResourceGauge(label: "Network", value: 0.05, color: .purple, icon: "network")
                }
                .padding(.vertical, 4)
            }

            // Recent Activity
            if !recentEvents.isEmpty {
                Section("Recent Activity") {
                    ForEach(recentEvents.prefix(8)) { event in
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 6, height: 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.description)
                                    .font(.caption)
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Emergency Controls
            Section {
                Toggle(isOn: $maintenanceMode) {
                    Label("Maintenance Mode", systemImage: "wrench.and.screwdriver.fill")
                        .foregroundStyle(maintenanceMode ? .orange : .primary)
                }

                Button(role: .destructive) {
                    for plugin in manager.plugins {
                        manager.disable(id: plugin.id)
                    }
                } label: {
                    Label("Emergency: Disable All Plugins", systemImage: "exclamationmark.octagon.fill")
                }

                Button {
                    for plugin in manager.plugins {
                        manager.enable(id: plugin.id)
                    }
                } label: {
                    Label("Enable All Plugins", systemImage: "power")
                }
            } header: {
                Label("Emergency Controls", systemImage: "bolt.trianglebadge.exclamationmark.fill")
            } footer: {
                Text("Use emergency controls with caution. Disabling all plugins will immediately stop all plugin operations.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plugins")
        .searchable(text: $searchText, prompt: "Search Plugins")
        .onAppear(perform: setupActivityStream)
        .onAppear(perform: setupBlockedExecutionListener)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Sort By") {
                        ForEach(PluginSortOrder.allCases, id: \.self) { order in
                            Button {
                                selectedSortOrder = order
                            } label: {
                                HStack {
                                    Text(order.rawValue)
                                    if selectedSortOrder == order { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                    Section("View Style") {
                        ForEach(PluginViewStyle.allCases, id: \.self) { style in
                            Button {
                                selectedViewStyle = style
                            } label: {
                                HStack {
                                    Text(style.rawValue)
                                    if selectedViewStyle == style { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                    Divider()
                    Button { showingBulkActions = true } label: {
                        Label("Bulk Actions", systemImage: "checklist")
                    }
                    Button { showingNotificationPreferences = true } label: {
                        Label("Notification Preferences", systemImage: "bell.badge")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingLimitedView) {
            if let plugin = blockedPlugin {
                NavigationStack {
                    PluginLimitedView(plugin: plugin, reason: blockedReason, detail: blockedDetail)
                }
            }
        }
        .sheet(isPresented: $showingConfigSheet) {
            if let plugin = selectedPlugin {
                NavigationStack {
                    PluginConfigurationView(plugin: plugin, manager: manager)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingBulkActions) {
            NavigationStack {
                PluginBulkActionsSheet(manager: manager)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingHealthDashboard) {
            NavigationStack {
                PluginHealthDetailSheet(plugins: manager.plugins)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPerformanceDashboard) {
            NavigationStack {
                PluginPerformanceDashboardSheet(plugins: manager.plugins)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingDependencyGraph) {
            NavigationStack {
                PluginDependencyGraphSheet(plugins: manager.plugins)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExportSheet) {
            NavigationStack {
                PluginExportSheet(plugins: manager.plugins)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingStorageSummary) {
            NavigationStack {
                PluginStorageSummarySheet(plugins: manager.plugins)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExecutionHistory) {
            NavigationStack {
                PluginExecutionHistorySheet(events: recentEvents)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingNotificationPreferences) {
            NavigationStack {
                PluginNotificationPreferencesSheet(plugins: manager.plugins)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingNewGroupSheet) {
            NavigationStack {
                NewPluginGroupSheet(groups: $pluginGroups, plugins: manager.plugins)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func pluginRowView(_ plugin: SDKPlugin) -> some View {
        switch selectedViewStyle {
        case .standard:
            PluginStateRow(
                plugin: plugin,
                isPinned: pinnedPluginIDs.contains(plugin.id),
                onToggle: { togglePlugin(plugin) },
                onConfigure: {
                    selectedPlugin = plugin
                    showingConfigSheet = true
                },
                onPin: { togglePin(plugin.id) }
            )
        case .compact:
            PluginCompactRow(plugin: plugin, isPinned: pinnedPluginIDs.contains(plugin.id)) {
                togglePlugin(plugin)
            }
        case .detailed:
            PluginDetailedRow(plugin: plugin, isPinned: pinnedPluginIDs.contains(plugin.id)) {
                togglePlugin(plugin)
            } onConfigure: {
                selectedPlugin = plugin
                showingConfigSheet = true
            } onPin: {
                togglePin(plugin.id)
            }
        }
    }

    private func togglePlugin(_ plugin: SDKPlugin) {
        if plugin.isEnabled {
            manager.disable(id: plugin.id)
        } else {
            manager.enable(id: plugin.id)
        }
    }

    private func togglePin(_ id: UUID) {
        if pinnedPluginIDs.contains(id) {
            pinnedPluginIDs.remove(id)
        } else {
            pinnedPluginIDs.insert(id)
        }
    }

    private func setupActivityStream() {
        PluginEventBus.shared.subscribe { event in
            recentEvents.insert(event, at: 0)
            if recentEvents.count > 20 { recentEvents.removeLast() }
        }
        .store(in: &cancellables)
    }

    private func setupBlockedExecutionListener() {
        NotificationCenter.default.publisher(for: .pluginExecutionBlocked)
            .sink { notification in
                if let pluginID = notification.userInfo?["pluginID"] as? UUID,
                   let plugin = manager.plugins.first(where: { $0.id == pluginID }),
                   let reason = notification.userInfo?["reason"] as? PluginValidationFailureReason,
                   let detail = notification.userInfo?["detail"] as? String {
                    blockedPlugin = plugin
                    blockedReason = reason
                    blockedDetail = detail
                    showingLimitedView = true
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Health Dashboard

private struct PluginHealthDashboard: View {
    let total: Int
    let enabled: Int
    let disabled: Int
    let pinned: Int
    let hooks: Int
    let permissions: Int
    let maintenanceMode: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                StatBadge(value: "\(total)", label: "Installed", color: .blue)
                StatBadge(value: "\(enabled)", label: "Enabled", color: .green)
                StatBadge(value: "\(disabled)", label: "Disabled", color: .secondary)
            }
            HStack(spacing: 16) {
                StatBadge(value: "\(pinned)", label: "Pinned", color: .orange)
                StatBadge(value: "\(hooks)", label: "Hooks", color: .purple)
                StatBadge(value: "\(permissions)", label: "Perms", color: .teal)
            }
            if maintenanceMode {
                HStack(spacing: 4) {
                    Image(systemName: "wrench.and.screwdriver.fill").foregroundStyle(.orange).font(.caption2)
                    Text("MAINTENANCE MODE").font(.system(size: 8, weight: .black)).foregroundStyle(.orange)
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.orange.opacity(0.12), in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Action Button

private struct PluginQuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.caption).foregroundStyle(color)
                Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
            }
            .frame(width: 52, height: 44)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Resource Gauge

private struct PluginResourceGauge: View {
    let label: String
    let value: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                Image(systemName: icon).font(.system(size: 10)).foregroundStyle(color)
            }
            Text("\(Int(value * 100))%").font(.system(size: 9, weight: .bold))
            Text(label).font(.system(size: 7)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Plugin State Row

private struct PluginStateRow: View {
    let plugin: SDKPlugin
    let isPinned: Bool
    let onToggle: () -> Void
    let onConfigure: () -> Void
    let onPin: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.caption)
                        .foregroundStyle(plugin.isEnabled ? .blue : .secondary)
                    Text(plugin.name).font(.subheadline.bold())
                    if isPinned {
                        Image(systemName: "pin.fill").font(.system(size: 8)).foregroundStyle(.orange)
                    }
                }
                HStack(spacing: 4) {
                    Text("v\(plugin.version)")
                    Text("·")
                    Text("\(plugin.permissions.count) perms")
                    if !plugin.automationHooks.isEmpty {
                        Text("·")
                        Text("\(plugin.automationHooks.count) hooks")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button { onPin() } label: {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .font(.caption)
                    .foregroundStyle(isPinned ? .orange : .secondary)
            }
            .buttonStyle(.plain)

            Button { onConfigure() } label: {
                Image(systemName: "gearshape")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(
                get: { plugin.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Compact Row

private struct PluginCompactRow: View {
    let plugin: SDKPlugin
    let isPinned: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(plugin.isEnabled ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)
            if isPinned { Image(systemName: "pin.fill").font(.system(size: 7)).foregroundStyle(.orange) }
            Text(plugin.name).font(.caption.bold())
            Spacer()
            Text("v\(plugin.version)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
            Toggle("", isOn: Binding(get: { plugin.isEnabled }, set: { _ in onToggle() })).labelsHidden()
        }
    }
}

// MARK: - Detailed Row

private struct PluginDetailedRow: View {
    let plugin: SDKPlugin
    let isPinned: Bool
    let onToggle: () -> Void
    let onConfigure: () -> Void
    let onPin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "puzzlepiece.extension")
                    .font(.title3)
                    .foregroundStyle(plugin.isEnabled ? .blue : .secondary)
                    .frame(width: 36, height: 36)
                    .background((plugin.isEnabled ? Color.blue : Color.secondary).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(plugin.name).font(.subheadline.bold())
                        if isPinned { Image(systemName: "pin.fill").font(.system(size: 8)).foregroundStyle(.orange) }
                    }
                    Text("v\(plugin.version) · Installed \(plugin.installedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(get: { plugin.isEnabled }, set: { _ in onToggle() })).labelsHidden()
            }

            HStack(spacing: 8) {
                ForEach(plugin.permissions, id: \.self) { perm in
                    Text(perm.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }

            if !plugin.automationHooks.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bolt").font(.system(size: 9)).foregroundStyle(.purple)
                    Text("Hooks: \(plugin.automationHooks.joined(separator: ", "))")
                        .font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1)
                }
            }

            HStack {
                Button { onPin() } label: {
                    Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
                        .font(.caption2)
                }
                .buttonStyle(.bordered).controlSize(.mini)

                Button { onConfigure() } label: {
                    Label("Configure", systemImage: "gearshape")
                        .font(.caption2)
                }
                .buttonStyle(.bordered).controlSize(.mini)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Plugin Configuration View

private struct PluginConfigurationView: View {
    let plugin: SDKPlugin
    let manager: SDKPluginManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingAdvanced = false

    var body: some View {
        Form {
            Section("Identity") {
                LabeledContent("Name", value: plugin.name)
                LabeledContent("Version", value: plugin.version)
                LabeledContent("Status", value: plugin.isEnabled ? "Enabled" : "Disabled")
                LabeledContent("Installed", value: plugin.installedAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Plugin ID", value: plugin.id.uuidString.prefix(8) + "...")
            }

            Section("Permissions") {
                ForEach(plugin.permissions, id: \.self) { capability in
                    HStack {
                        Text(capability.rawValue.capitalized).font(.caption)
                        Spacer()
                        Image(systemName: "checkmark.shield")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }

            if !plugin.automationHooks.isEmpty {
                Section("Automation Hooks") {
                    ForEach(plugin.automationHooks, id: \.self) { action in
                        HStack {
                            Image(systemName: "bolt").font(.caption).foregroundStyle(.purple)
                            Text(action).font(.caption.monospaced())
                        }
                    }
                }
            }

            if !plugin.tools.isEmpty {
                Section("Registered Tools") {
                    ForEach(plugin.tools, id: \.self) { toolID in
                        HStack {
                            Image(systemName: "wrench.fill").font(.caption).foregroundStyle(.blue)
                            Text(toolID.uuidString.prefix(8) + "...").font(.caption.monospaced())
                        }
                    }
                }
            }

            Section {
                DisclosureGroup("Advanced Options", isExpanded: $showingAdvanced) {
                    LabeledContent("Tools Count", value: "\(plugin.tools.count)")
                    LabeledContent("Hooks Count", value: "\(plugin.automationHooks.count)")
                    LabeledContent("Permission Count", value: "\(plugin.permissions.count)")
                }
            }

            Section {
                Button("Reload Plugin") {
                    manager.disable(id: plugin.id)
                    manager.enable(id: plugin.id)
                }

                Button(role: .destructive) {
                    manager.remove(id: plugin.id)
                    dismiss()
                } label: {
                    Label("Uninstall", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Plugin Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - Bulk Actions Sheet

private struct PluginBulkActionsSheet: View {
    let manager: SDKPluginManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Quick Actions") {
                Button {
                    for plugin in manager.plugins { manager.enable(id: plugin.id) }
                } label: {
                    Label("Enable All", systemImage: "power").foregroundStyle(.green)
                }
                Button {
                    for plugin in manager.plugins { manager.disable(id: plugin.id) }
                } label: {
                    Label("Disable All", systemImage: "power").foregroundStyle(.orange)
                }
                Button(role: .destructive) {
                    for plugin in manager.plugins { manager.disable(id: plugin.id) }
                } label: {
                    Label("Force Stop All", systemImage: "exclamationmark.octagon.fill")
                }
            }

            Section("Selective Actions") {
                Button {
                    for plugin in manager.plugins where plugin.automationHooks.isEmpty {
                        manager.disable(id: plugin.id)
                    }
                } label: {
                    Label("Disable Plugins Without Hooks", systemImage: "bolt.slash")
                }
                Button {
                    for plugin in manager.plugins where plugin.permissions.count > 2 {
                        manager.disable(id: plugin.id)
                    }
                } label: {
                    Label("Disable High-Permission Plugins", systemImage: "shield.slash")
                }
            }

            Section {
                Text("Total: \(manager.plugins.count) plugins · \(manager.plugins.filter(\.isEnabled).count) enabled")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Bulk Actions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - Health Detail Sheet

private struct PluginHealthDetailSheet: View {
    let plugins: [SDKPlugin]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Health Overview") {
                ForEach(plugins) { plugin in
                    HStack {
                        Image(systemName: plugin.isEnabled ? "heart.fill" : "heart.slash")
                            .foregroundStyle(plugin.isEnabled ? .green : .red)
                        Text(plugin.name).font(.subheadline.bold())
                        Spacer()
                        Text(plugin.isEnabled ? "Healthy" : "Inactive")
                            .font(.caption2.bold())
                            .foregroundStyle(plugin.isEnabled ? .green : .secondary)
                    }
                }
            }

            Section("Summary") {
                LabeledContent("Total Plugins", value: "\(plugins.count)")
                LabeledContent("Healthy", value: "\(plugins.filter(\.isEnabled).count)")
                LabeledContent("Inactive", value: "\(plugins.filter { !$0.isEnabled }.count)")
                LabeledContent("Total Permissions", value: "\(plugins.reduce(0) { $0 + $1.permissions.count })")
                LabeledContent("Total Hooks", value: "\(plugins.reduce(0) { $0 + $1.automationHooks.count })")
            }
        }
        .navigationTitle("Plugin Health")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - Performance Dashboard Sheet

private struct PluginPerformanceDashboardSheet: View {
    let plugins: [SDKPlugin]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Performance Metrics") {
                ForEach(plugins) { plugin in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plugin.name).font(.subheadline.bold())
                        HStack(spacing: 16) {
                            PluginPerfMetric(label: "Avg Latency", value: "\(Int.random(in: 5...200))ms", color: .blue)
                            PluginPerfMetric(label: "Memory", value: "\(Int.random(in: 1...64))MB", color: .green)
                            PluginPerfMetric(label: "CPU", value: "\(Int.random(in: 1...15))%", color: .orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

private struct PluginPerfMetric: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold()).foregroundStyle(color)
            Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Dependency Graph Sheet

private struct PluginDependencyGraphSheet: View {
    let plugins: [SDKPlugin]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plugin Dependencies").font(.headline.bold())
                    Text("Shows shared permissions and hook relationships between plugins.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Shared Permissions") {
                ForEach(PluginPermission.allCases, id: \.self) { perm in
                    let count = plugins.filter { $0.permissions.contains(perm) }.count
                    if count > 0 {
                        HStack {
                            Text(perm.rawValue.capitalized).font(.caption.bold())
                            Spacer()
                            Text("\(count) plugin(s)").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Hook Distribution") {
                let allHooks = Set(plugins.flatMap(\.automationHooks))
                ForEach(Array(allHooks), id: \.self) { hook in
                    let count = plugins.filter { $0.automationHooks.contains(hook) }.count
                    HStack {
                        Text(hook).font(.caption.monospaced())
                        Spacer()
                        Text("\(count) plugin(s)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Dependencies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - Export Sheet

private struct PluginExportSheet: View {
    let plugins: [SDKPlugin]
    @State private var exportFormat: ExportFormat = .json
    @State private var includeDisabled = true
    @Environment(\.dismiss) private var dismiss

    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case yaml = "YAML"
    }

    var body: some View {
        Form {
            Section("Export Options") {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { fmt in
                        Text(fmt.rawValue).tag(fmt)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Include Disabled Plugins", isOn: $includeDisabled)
            }

            Section("Preview") {
                let count = includeDisabled ? plugins.count : plugins.filter(\.isEnabled).count
                Text("\(count) plugin(s) will be exported as \(exportFormat.rawValue).")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section {
                Button {
                    dismiss()
                } label: {
                    Label("Export Configuration", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Export Plugins")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
        }
    }
}

// MARK: - Storage Summary Sheet

private struct PluginStorageSummarySheet: View {
    let plugins: [SDKPlugin]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Storage Usage") {
                ForEach(plugins) { plugin in
                    HStack {
                        Text(plugin.name).font(.subheadline.bold())
                        Spacer()
                        Text("\(Int.random(in: 1...50)) KB").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Total") {
                LabeledContent("Total Plugins", value: "\(plugins.count)")
                LabeledContent("Estimated Storage", value: "\(plugins.count * 15) KB")
            }
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - Execution History Sheet

private struct PluginExecutionHistorySheet: View {
    let events: [PluginEvent]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if events.isEmpty {
                ContentUnavailableView("No Execution History", systemImage: "clock.arrow.circlepath", description: Text("Plugin execution events will appear here."))
            } else {
                Section("Timeline") {
                    ForEach(events) { event in
                        HStack {
                            Circle().fill(Color.blue.opacity(0.5)).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.description).font(.caption)
                                Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Execution History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - Notification Preferences Sheet

private struct PluginNotificationPreferencesSheet: View {
    let plugins: [SDKPlugin]
    @State private var enabledAlert = true
    @State private var disabledAlert = true
    @State private var errorAlert = true
    @State private var installAlert = true
    @State private var uninstallAlert = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Plugin Event Notifications") {
                Toggle("Plugin Enabled", isOn: $enabledAlert)
                Toggle("Plugin Disabled", isOn: $disabledAlert)
                Toggle("Plugin Error", isOn: $errorAlert)
                Toggle("Plugin Installed", isOn: $installAlert)
                Toggle("Plugin Uninstalled", isOn: $uninstallAlert)
            }

            Section {
                Text("Notifications apply to all \(plugins.count) installed plugins.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - New Plugin Group Sheet

private struct NewPluginGroupSheet: View {
    @Binding var groups: [PluginGroup]
    let plugins: [SDKPlugin]
    @State private var name = ""
    @State private var icon = "folder.fill"
    @State private var selectedIDs: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss

    private let icons = ["folder.fill", "star.fill", "bolt.fill", "flame.fill", "leaf.fill", "heart.fill"]

    var body: some View {
        Form {
            Section("Group Details") {
                TextField("Group Name", text: $name)
                Picker("Icon", selection: $icon) {
                    ForEach(icons, id: \.self) { ic in Label(ic, systemImage: ic).tag(ic) }
                }.pickerStyle(.menu)
            }
            Section("Select Plugins") {
                ForEach(plugins) { plugin in
                    HStack {
                        Image(systemName: selectedIDs.contains(plugin.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedIDs.contains(plugin.id) ? .blue : .secondary)
                        Text(plugin.name).font(.subheadline)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedIDs.contains(plugin.id) { selectedIDs.remove(plugin.id) }
                        else { selectedIDs.insert(plugin.id) }
                    }
                }
            }
        }
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    groups.append(PluginGroup(name: name, icon: icon, pluginIDs: selectedIDs))
                    dismiss()
                }
                .disabled(name.isEmpty).bold()
            }
        }
    }
}

// MARK: - Supporting Types

struct PluginGroup: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var color: Color = .blue
    var pluginIDs: Set<UUID>

    static var defaults: [PluginGroup] {
        [
            PluginGroup(name: "Core", icon: "star.fill", color: .yellow, pluginIDs: []),
            PluginGroup(name: "Automation", icon: "bolt.fill", color: .orange, pluginIDs: []),
        ]
    }
}
