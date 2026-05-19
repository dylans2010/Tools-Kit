import SwiftUI

struct SDKModuleRegistryView: View {
    @StateObject private var registry = SDKModuleRegistry.shared
    @State private var showingAddModule = false
    @State private var showingDependencyGraph = false
    @State private var selectedModule: SDKModuleDescriptor?
    @State private var searchText = ""
    @State private var filterCapability: SDKModuleCapability?

    private var filteredModules: [SDKModuleDescriptor] {
        var result = registry.modules
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.identifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let cap = filterCapability {
            result = result.filter { $0.capabilities.contains(cap) }
        }
        return result
    }

    var body: some View {
        List {
            overviewSection
            if !filteredModules.isEmpty { modulesSection }
            actionsSection
            if !registry.registrationLog.isEmpty { logSection }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search modules")
        .navigationTitle("Module Registry")
        .sheet(isPresented: $showingAddModule) {
            NavigationStack { addModuleSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedModule) { (mod: SDKModuleDescriptor) in
            NavigationStack { moduleDetailSheet(mod) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingDependencyGraph) {
            NavigationStack { dependencyGraphSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var overviewSection: some View {
        Section {
            LabeledContent("Registered Modules", value: "\(registry.modules.count)")
            LabeledContent("Active", value: "\(registry.activeModuleIDs.count)")
            LabeledContent("Inactive", value: "\(registry.modules.count - registry.activeModuleIDs.count)")

            if let cap = filterCapability {
                HStack {
                    Text("Filtering: \(cap.rawValue)").font(.caption).foregroundStyle(Color.accentColor)
                    Spacer()
                    Button("Clear") { filterCapability = nil }.font(.caption)
                }
            }
        } header: {
            Text("Overview")
        }
    }

    @ViewBuilder
    private var modulesSection: some View {
        let modules = filteredModules
        Section {
            ForEach(modules) { mod in
                Button { selectedModule = mod } label: { moduleRow(mod) }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                let toRemove = offsets.map { modules[$0].identifier }
                toRemove.forEach { registry.unregister(identifier: $0) }
            }
        } header: {
            Text("Modules (\(modules.count))")
        }
    }

    private func moduleRow(_ mod: SDKModuleDescriptor) -> some View {
        let previewCapabilities = Array(mod.capabilities.prefix(3))
        let extraCount = max(0, mod.capabilities.count - 3)
        let isActive = registry.activeModuleIDs.contains(mod.id)

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mod.displayName).font(.subheadline.bold())
                    Text("v\(mod.version)")
                        .font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                Text(mod.identifier)
                    .font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                HStack(spacing: 6) {
                    ForEach(previewCapabilities, id: \.self) { cap in
                        Text(cap.rawValue)
                            .font(.system(size: 8, weight: .medium))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                    if extraCount > 0 {
                        Text("+\(extraCount)")
                            .font(.system(size: 8)).foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
            Circle()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)
        }
    }

    private var actionsSection: some View {
        Section {
            Button { showingAddModule = true } label: {
                Label("Register New Module", systemImage: "plus.circle.fill")
            }
            Button { showingDependencyGraph = true } label: {
                Label("Dependency Graph", systemImage: "point.3.connected.trianglepath.dotted")
            }
        } header: {
            Text("Actions")
        }
    }

    private var logSection: some View {
        Section {
            ForEach(registry.registrationLog.prefix(10)) { event in
                HStack {
                    Text(event.moduleIdentifier).font(.caption.bold())
                    Spacer()
                    Text(event.action)
                        .font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("Recent Activity")
        }
    }

    @State private var newModIdentifier = ""
    @State private var newModDisplayName = ""
    @State private var newModVersion = "1.0.0"
    @State private var newModCapabilities: Set<SDKModuleCapability> = []

    private var addModuleSheet: some View {
        Form {
            Section("Module Details") {
                TextField("Identifier (e.g. com.app.module)", text: $newModIdentifier)
                    .font(.system(size: 13, design: .monospaced))
                TextField("Display Name", text: $newModDisplayName)
                TextField("Version", text: $newModVersion)
            }
            Section("Capabilities") {
                ForEach(SDKModuleCapability.allCases, id: \.self) { cap in
                    Toggle(cap.rawValue, isOn: Binding(
                        get: { newModCapabilities.contains(cap) },
                        set: { if $0 { newModCapabilities.insert(cap) } else { newModCapabilities.remove(cap) } }
                    ))
                    .font(.caption)
                }
            }
        }
        .navigationTitle("Register Module")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddModule = false } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Register") {
                    let descriptor = SDKModuleDescriptor(
                        identifier: newModIdentifier,
                        displayName: newModDisplayName,
                        version: newModVersion,
                        capabilities: Array(newModCapabilities)
                    )
                    try? registry.register(descriptor)
                    showingAddModule = false
                    newModIdentifier = ""
                    newModDisplayName = ""
                    newModVersion = "1.0.0"
                    newModCapabilities = []
                }
                .disabled(newModIdentifier.isEmpty || newModDisplayName.isEmpty)
            }
        }
    }

    @ViewBuilder
    private func moduleDetailSheet(_ mod: SDKModuleDescriptor) -> some View {
        List {
            Section("Details") {
                LabeledContent("Identifier", value: mod.identifier)
                LabeledContent("Display Name", value: mod.displayName)
                LabeledContent("Version", value: "v\(mod.version)")
                LabeledContent("Min SDK", value: mod.minimumSDKVersion)
                LabeledContent("Priority", value: "\(mod.loadPriority)")
                LabeledContent("Status", value: registry.activeModuleIDs.contains(mod.id) ? "Active" : "Inactive")
            }
            Section("Capabilities") {
                ForEach(mod.capabilities.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { cap in
                    Button { filterCapability = cap; selectedModule = nil } label: {
                        Label(cap.rawValue, systemImage: "cpu")
                    }
                }
            }
            if !mod.dependencies.isEmpty {
                Section("Dependencies") {
                    ForEach(mod.dependencies, id: \.self) { dep in
                        Text(dep).font(.caption.monospaced())
                    }
                }
            }
            if !mod.exportedServices.isEmpty {
                Section("Exported Services") {
                    ForEach(mod.exportedServices, id: \.self) { svc in
                        Text(svc).font(.caption.monospaced())
                    }
                }
            }
            Section("Actions") {
                if registry.activeModuleIDs.contains(mod.id) {
                    Button("Deactivate") {
                        Task { await registry.deactivate(identifier: mod.identifier) }
                        selectedModule = nil
                    }
                } else {
                    Button("Activate") {
                        Task { try? await registry.activate(identifier: mod.identifier) }
                        selectedModule = nil
                    }
                }
                Button("Unregister", role: .destructive) {
                    registry.unregister(identifier: mod.identifier)
                    selectedModule = nil
                }
            }
        }
        .navigationTitle(mod.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Done") { selectedModule = nil } }
        }
    }

    private var dependencyGraphSheet: some View {
        let resolution = SDKDependencyGraph().resolve(modules: registry.modules)
        let cleanText = resolution.isClean ? "Yes" : "No"
        let countText = "\(resolution.orderedModules.count)"
        let conflicts = resolution.conflicts
        let orderedModules = resolution.orderedModules
        let warnings = resolution.warnings

        return List {
            Section("Resolution") {
                LabeledContent("Clean", value: cleanText)
                LabeledContent("Ordered Modules", value: countText)
            }
            if !conflicts.isEmpty {
                Section("Conflicts") {
                    ForEach(conflicts) { conflict in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(conflict.description).font(.caption)
                                Text(conflict.conflictType.rawValue).font(.caption2).foregroundStyle(.tertiary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                    }
                }
            }
            Section("Load Order") {
                ForEach(Array(orderedModules.enumerated()), id: \.element.id) { index, mod in
                    HStack {
                        Text("\(index + 1)").font(.caption.monospaced()).foregroundStyle(.tertiary)
                        Text(mod.displayName).font(.caption.bold())
                        Spacer()
                        Text("v\(mod.version)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            if !warnings.isEmpty {
                Section("Warnings") {
                    ForEach(warnings, id: \.self) { warning in
                        Text(warning).font(.caption).foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle("Dependency Graph")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Done") { showingDependencyGraph = false } }
        }
    }
}
