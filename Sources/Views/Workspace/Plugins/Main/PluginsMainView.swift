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

    var filteredPlugins: [SDKPlugin] {
        if searchText.isEmpty { return manager.plugins }
        return manager.plugins.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var enabledPlugins: [SDKPlugin] { filteredPlugins.filter(\.isEnabled) }
    var disabledPlugins: [SDKPlugin] { filteredPlugins.filter { !$0.isEnabled } }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    StatBadge(value: "\(manager.plugins.count)", label: "Installed", color: .blue)
                    StatBadge(value: "\(enabledPlugins.count)", label: "Enabled", color: .green)
                    StatBadge(value: "\(disabledPlugins.count)", label: "Disabled", color: .secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Overview")
            }

            if !enabledPlugins.isEmpty {
                Section("Active Plugins") {
                    ForEach(enabledPlugins) { plugin in
                        PluginStateRow(
                            plugin: plugin,
                            onToggle: { manager.disable(id: plugin.id) },
                            onConfigure: {
                                selectedPlugin = plugin
                                showingConfigSheet = true
                            }
                        )
                    }
                }
            }

            if !disabledPlugins.isEmpty {
                Section("Inactive Plugins") {
                    ForEach(disabledPlugins) { plugin in
                        PluginStateRow(
                            plugin: plugin,
                            onToggle: { manager.enable(id: plugin.id) },
                            onConfigure: {
                                selectedPlugin = plugin
                                showingConfigSheet = true
                            }
                        )
                    }
                }
            }

            Section("Development") {
                NavigationLink(destination: PluginBuildView()) {
                    Label("Builder", systemImage: "wrench.and.screwdriver")
                }
                NavigationLink(destination: PluginDevConsoleView()) {
                    Label("Developer Console", systemImage: "terminal")
                }
                NavigationLink(destination: MarketplaceView()) {
                    Label("Marketplace", systemImage: "storefront")
                }
            }

            Section("Management") {
                NavigationLink(destination: PluginsInstalledView()) {
                    Label("All Installed", systemImage: "square.stack.3d.up")
                }
                NavigationLink(destination: ConnectorsMainView()) {
                    Label("Plugin Connectors", systemImage: "cable.connector")
                }
                NavigationLink(destination: PluginSecurityView()) {
                    Label("Security", systemImage: "lock.shield")
                }
            }

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
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plugins")
        .searchable(text: $searchText, prompt: "Search Plugins")
        .onAppear(perform: setupActivityStream)
        .onAppear(perform: setupBlockedExecutionListener)
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

// MARK: - Plugin State Row

private struct PluginStateRow: View {
    let plugin: SDKPlugin
    let onToggle: () -> Void
    let onConfigure: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.caption)
                        .foregroundStyle(plugin.isEnabled ? .blue : .secondary)
                    Text(plugin.name).font(.subheadline.bold())
                }
                Text("v\(plugin.version)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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

// MARK: - Plugin Configuration View

private struct PluginConfigurationView: View {
    let plugin: SDKPlugin
    let manager: SDKPluginManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Identity") {
                LabeledContent("Name", value: plugin.name)
                LabeledContent("Version", value: plugin.version)
                LabeledContent("Status", value: plugin.isEnabled ? "Enabled" : "Disabled")
                LabeledContent("Installed", value: plugin.installedAt.formatted(date: .abbreviated, time: .shortened))
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
                        Text(action).font(.caption.monospaced())
                    }
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
