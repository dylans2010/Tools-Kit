import SwiftUI

struct SDKPluginLifecycleView: View {
    @StateObject private var lifecycle = SDKPluginLifecycleManager.shared
    @State private var showingInstall = false
    @State private var selectedManifest: SDKPluginManifest?
    @State private var searchText = ""
    @State private var filterPhase: SDKPluginPhase?

    private var filteredManifests: [SDKPluginManifest] {
        var result = lifecycle.manifests
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.identifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let phase = filterPhase {
            result = result.filter { lifecycle.phases[$0.id] == phase }
        }
        return result
    }

    var body: some View {
        List {
            overviewSection
            if !filteredManifests.isEmpty { pluginsSection }
            actionsSection
            if !lifecycle.lifecycleLog.isEmpty { logSection }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search plugins")
        .navigationTitle("Plugin Lifecycle")
        .sheet(isPresented: $showingInstall) {
            NavigationStack { installPluginSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedManifest) { manifest in
            NavigationStack { manifestDetailSheet(manifest) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var overviewSection: some View {
        Section {
            LabeledContent("Installed", value: "\(lifecycle.manifests.count)")
            LabeledContent("Active", value: "\(lifecycle.pluginsInPhase(.active).count)")
            LabeledContent("Paused", value: "\(lifecycle.pluginsInPhase(.paused).count)")
            LabeledContent("Errored", value: "\(lifecycle.pluginsInPhase(.errored).count)")

            if let phase = filterPhase {
                HStack {
                    Text("Filtering: \(phase.rawValue)").font(.caption).foregroundStyle(Color.accentColor)
                    Spacer()
                    Button("Clear") { filterPhase = nil }.font(.caption)
                }
            }
        } header: {
            Text("Overview")
        }
    }

    private var pluginsSection: some View {
        Section {
            ForEach(filteredManifests) { manifest in
                Button { selectedManifest = manifest } label: {
                    HStack {
                        Image(systemName: manifest.iconName)
                            .font(.title3).foregroundStyle(Color.accentColor)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(manifest.displayName).font(.subheadline.bold())
                                Text("v\(manifest.version)")
                                    .font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            Text(manifest.identifier)
                                .font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                            HStack(spacing: 8) {
                                Text(manifest.category.rawValue)
                                    .font(.system(size: 8, weight: .medium))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1), in: Capsule())
                                    .foregroundStyle(Color.accentColor)
                                Text("\(manifest.capabilities.count) capabilities")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        phaseIndicator(for: manifest)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                let toRemove = offsets.map { filteredManifests[$0] }
                Task {
                    for manifest in toRemove {
                        await lifecycle.uninstall(identifier: manifest.identifier)
                    }
                }
            }
        } header: {
            Text("Plugins (\(filteredManifests.count))")
        }
    }

    private var actionsSection: some View {
        Section {
            Button { showingInstall = true } label: {
                Label("Install Plugin", systemImage: "plus.circle.fill")
            }

            Menu {
                ForEach(SDKPluginPhase.allCases, id: \.self) { phase in
                    Button(phase.rawValue.capitalized) { filterPhase = phase }
                }
                Button("All") { filterPhase = nil }
            } label: {
                Label("Filter by Phase", systemImage: "line.3.horizontal.decrease.circle")
            }
        } header: {
            Text("Actions")
        }
    }

    private var logSection: some View {
        Section {
            ForEach(lifecycle.lifecycleLog.prefix(15)) { event in
                HStack {
                    Text(event.pluginIdentifier)
                        .font(.caption.bold()).lineLimit(1)
                    Spacer()
                    Text("\(event.fromPhase) → \(event.toPhase)")
                        .font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                    Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("Lifecycle Events")
        }
    }

    @ViewBuilder
    private func phaseIndicator(for manifest: SDKPluginManifest) -> some View {
        let phase = lifecycle.phases[manifest.id] ?? .unloaded
        Text(phase.rawValue)
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(phaseColor(phase).opacity(0.15), in: Capsule())
            .foregroundStyle(phaseColor(phase))
    }

    private func phaseColor(_ phase: SDKPluginPhase) -> Color {
        switch phase {
        case .unloaded: return .secondary
        case .loading: return .blue
        case .active: return .green
        case .paused: return .orange
        case .updating, .migrating: return .purple
        case .errored: return .red
        case .disabled: return .secondary
        }
    }

    @State private var newPluginIdentifier = ""
    @State private var newPluginDisplayName = ""
    @State private var newPluginVersion = "1.0.0"
    @State private var newPluginAuthor = ""
    @State private var newPluginCategory: SDKPluginManifest.PluginCategory = .utility

    private var installPluginSheet: some View {
        Form {
            Section("Plugin Details") {
                TextField("Identifier (e.g. com.app.plugin)", text: $newPluginIdentifier)
                    .font(.system(size: 13, design: .monospaced))
                TextField("Display Name", text: $newPluginDisplayName)
                TextField("Version", text: $newPluginVersion)
                TextField("Author", text: $newPluginAuthor)
                Picker("Category", selection: $newPluginCategory) {
                    ForEach(SDKPluginManifest.PluginCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue.capitalized).tag(cat)
                    }
                }
            }
        }
        .navigationTitle("Install Plugin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingInstall = false } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Install") {
                    let manifest = SDKPluginManifest(
                        identifier: newPluginIdentifier,
                        displayName: newPluginDisplayName,
                        version: newPluginVersion,
                        author: newPluginAuthor,
                        category: newPluginCategory
                    )
                    try? lifecycle.install(manifest)
                    showingInstall = false
                    newPluginIdentifier = ""
                    newPluginDisplayName = ""
                    newPluginVersion = "1.0.0"
                    newPluginAuthor = ""
                }
                .disabled(newPluginIdentifier.isEmpty || newPluginDisplayName.isEmpty)
            }
        }
    }

    @ViewBuilder
    private func manifestDetailSheet(_ manifest: SDKPluginManifest) -> some View {
        let phase = lifecycle.phases[manifest.id] ?? .unloaded
        List {
            Section("Details") {
                LabeledContent("Identifier", value: manifest.identifier)
                LabeledContent("Version", value: "v\(manifest.version)")
                LabeledContent("Author", value: manifest.author.isEmpty ? "Unknown" : manifest.author)
                LabeledContent("Category", value: manifest.category.rawValue.capitalized)
                LabeledContent("Min SDK", value: manifest.minimumSDKVersion)
                LabeledContent("Phase", value: phase.rawValue.capitalized)
            }
            if !manifest.description.isEmpty {
                Section("Description") {
                    Text(manifest.description).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            if !manifest.capabilities.isEmpty {
                Section("Capabilities (\(manifest.capabilities.count))") {
                    ForEach(manifest.capabilities) { cap in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cap.name).font(.caption.bold())
                            if !cap.description.isEmpty {
                                Text(cap.description).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            if !manifest.permissions.isEmpty {
                Section("Permissions") {
                    ForEach(manifest.permissions, id: \.self) { perm in
                        Label(perm.rawValue, systemImage: "lock.shield")
                            .font(.caption)
                    }
                }
            }
            Section("Lifecycle Actions") {
                switch phase {
                case .unloaded, .disabled:
                    Button("Load") {
                        Task { await lifecycle.transition(identifier: manifest.identifier, to: .loading) }
                    }
                case .loading:
                    Button("Activate") {
                        Task { await lifecycle.transition(identifier: manifest.identifier, to: .active) }
                    }
                case .active:
                    Button("Pause") {
                        Task { await lifecycle.transition(identifier: manifest.identifier, to: .paused) }
                    }
                    Button("Disable") {
                        Task { await lifecycle.transition(identifier: manifest.identifier, to: .disabled) }
                    }
                case .paused:
                    Button("Resume") {
                        Task { await lifecycle.transition(identifier: manifest.identifier, to: .active) }
                    }
                case .errored:
                    Button("Retry Load") {
                        Task { await lifecycle.transition(identifier: manifest.identifier, to: .loading) }
                    }
                default:
                    Text("No actions available").font(.caption).foregroundStyle(.secondary)
                }

                Button("Uninstall", role: .destructive) {
                    Task { await lifecycle.uninstall(identifier: manifest.identifier) }
                    selectedManifest = nil
                }
            }
        }
        .navigationTitle(manifest.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Done") { selectedManifest = nil } }
        }
    }
}
