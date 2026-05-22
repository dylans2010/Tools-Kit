// ToolsKit — SDKPluginRegistryView.swift
// SDK Expansion — Phase 4

import SwiftUI

struct SDKPluginRegistryView: View {
    @StateObject private var registry = SDKPluginRegistry.shared
    @State private var searchText = ""
    @State private var selectedCategory: SDKPluginCategory?
    @State private var selectedPlugin: SDKPluginInfo?

    private var filteredPlugins: [SDKPluginInfo] {
        var result = registry.registeredPlugins
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.identifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        return result
    }

    var body: some View {
        List {
            overviewSection
            categoryFilterSection
            pluginsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plugin Registry")
        .searchable(text: $searchText, prompt: "Search Plugins")
        .sheet(item: $selectedPlugin) { plugin in
            NavigationStack {
                pluginDetailSheet(plugin)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var overviewSection: some View {
        Section("Registry Overview") {
            LabeledContent("Registered", value: "\(registry.registeredPlugins.count)")
            LabeledContent("Active", value: "\(registry.activePluginCount)")

            let categories = Set(registry.registeredPlugins.map(\.category))
            LabeledContent("Categories", value: "\(categories.count)")
        }
    }

    private var categoryFilterSection: some View {
        Section("Category") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    PluginCategoryChip(label: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(SDKPluginCategory.allCases, id: \.self) { category in
                        let count = registry.plugins(inCategory: category).count
                        if count > 0 {
                            PluginCategoryChip(
                                label: "\(category.rawValue.capitalized) (\(count))",
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
    }

    private var pluginsSection: some View {
        Section("Plugins (\(filteredPlugins.count))") {
            if filteredPlugins.isEmpty {
                ContentUnavailableView(
                    "No Plugins",
                    systemImage: "puzzlepiece.extension",
                    description: Text("No plugins match your criteria.")
                )
            } else {
                ForEach(filteredPlugins) { plugin in
                    Button { selectedPlugin = plugin } label: {
                        PluginRegistryRow(plugin: plugin)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func pluginDetailSheet(_ plugin: SDKPluginInfo) -> some View {
        List {
            Section("Plugin Info") {
                LabeledContent("Name", value: plugin.displayName)
                LabeledContent("Identifier", value: plugin.identifier)
                LabeledContent("Version", value: plugin.version)
                LabeledContent("Category", value: plugin.category.rawValue.capitalized)
                LabeledContent("Phase", value: plugin.phase.rawValue.capitalized)
            }

            if !plugin.description.isEmpty {
                Section("Description") {
                    Text(plugin.description)
                        .font(.caption)
                }
            }

            if !plugin.capabilities.isEmpty {
                Section("Capabilities") {
                    ForEach(plugin.capabilities) { capability in
                        Label(capability.name, systemImage: "checkmark.circle")
                            .font(.caption)
                    }
                }
            }

            if !plugin.scopes.isEmpty {
                Section("Required Scopes") {
                    ForEach(plugin.scopes, id: \.self) { scope in
                        Text(scope)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }

            Section("Actions") {
                if plugin.phase == .active {
                    Button {
                        Task { try? await registry.pause(identifier: plugin.identifier) }
                        selectedPlugin = nil
                    } label: {
                        Label("Pause", systemImage: "pause.circle")
                    }

                    Button(role: .destructive) {
                        Task { try? await registry.deactivate(identifier: plugin.identifier) }
                        selectedPlugin = nil
                    } label: {
                        Label("Deactivate", systemImage: "stop.circle")
                    }
                } else if plugin.phase == .paused {
                    Button {
                        Task { try? await registry.resume(identifier: plugin.identifier) }
                        selectedPlugin = nil
                    } label: {
                        Label("Resume", systemImage: "play.circle")
                    }
                } else {
                    Button {
                        Task { try? await registry.activate(identifier: plugin.identifier) }
                        selectedPlugin = nil
                    } label: {
                        Label("Activate", systemImage: "play.circle.fill")
                    }
                }
            }
        }
        .navigationTitle(plugin.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PluginRegistryRow: View {
    let plugin: SDKPluginInfo

    var body: some View {
        HStack {
            Image(systemName: categoryIcon(plugin.category))
                .foregroundStyle(categoryColor(plugin.category))
                .font(.title3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(plugin.displayName)
                        .font(.subheadline.bold())
                    Text("v\(plugin.version)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Text(plugin.identifier)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            phaseLabel(plugin.phase)
        }
        .padding(.vertical, 2)
    }

    private func phaseLabel(_ phase: SDKPluginPhase) -> some View {
        Text(phase.rawValue.uppercased())
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(phaseColor(phase).opacity(0.15), in: Capsule())
            .foregroundStyle(phaseColor(phase))
    }

    private func phaseColor(_ phase: SDKPluginPhase) -> Color {
        switch phase {
        case .active: return .green
        case .paused: return .orange
        case .loading, .updating, .migrating: return .blue
        case .errored: return .red
        case .disabled, .unloaded: return .gray
        }
    }

    private func categoryIcon(_ category: SDKPluginCategory) -> String {
        switch category {
        case .analytics: return "chart.bar"
        case .communication: return "bubble.left.and.bubble.right"
        case .dataProcessing: return "cpu"
        case .integration: return "link"
        case .monitoring: return "waveform.path.ecg"
        case .security: return "lock.shield"
        case .ui: return "paintpalette"
        case .utility: return "wrench.and.screwdriver"
        case .automation: return "gearshape.2"
        case .storage: return "externaldrive"
        }
    }

    private func categoryColor(_ category: SDKPluginCategory) -> Color {
        switch category {
        case .analytics: return .blue
        case .communication: return .green
        case .dataProcessing: return .purple
        case .integration: return .orange
        case .monitoring: return .cyan
        case .security: return .red
        case .ui: return .pink
        case .utility: return .gray
        case .automation: return .indigo
        case .storage: return .brown
        }
    }
}

private struct PluginCategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SDKPluginRegistryView()
    }
}
