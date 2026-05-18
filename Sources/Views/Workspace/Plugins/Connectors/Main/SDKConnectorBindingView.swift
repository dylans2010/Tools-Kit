import SwiftUI

struct SDKConnectorBindingView: View {
    @ObservedObject private var binder = SDKConnectorRuntimeBinder.shared
    @ObservedObject private var connectorManager = SDKConnectorManager.shared
    @ObservedObject private var moduleRegistry = SDKModuleRegistry.shared
    @State private var showingAddBinding = false
    @State private var showingTemplates = false
    @State private var selectedBinding: ConnectorBinding?
    @State private var searchText = ""

    private var filteredBindings: [ConnectorBinding] {
        if searchText.isEmpty { return binder.bindings }
        return binder.bindings.filter {
            $0.moduleIdentifier.localizedCaseInsensitiveContains(searchText) ||
            $0.bindingType.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            overviewSection
            if !filteredBindings.isEmpty { bindingsSection }
            templatesSection
            streamsSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search bindings")
        .navigationTitle("Connector Bindings")
        .sheet(isPresented: $showingAddBinding) {
            NavigationStack { addBindingSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTemplates) {
            NavigationStack { templateBrowserSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedBinding) { binding in
            NavigationStack { bindingDetailSheet(binding) }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var overviewSection: some View {
        Section {
            LabeledContent("Active Bindings", value: "\(binder.bindings.filter(\.isActive).count)")
            LabeledContent("Total Bindings", value: "\(binder.bindings.count)")
            LabeledContent("Available Connectors", value: "\(connectorManager.connectors.count)")
            LabeledContent("Available Modules", value: "\(moduleRegistry.modules.count)")
            LabeledContent("Live Streams", value: "\(binder.liveStreams.filter(\.value).count)")
        } header: {
            Text("Overview")
        }
    }

    private var bindingsSection: some View {
        Section {
            ForEach(filteredBindings) { binding in
                Button { selectedBinding = binding } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(connectorName(for: binding.connectorID))
                                    .font(.subheadline.bold())
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9)).foregroundStyle(.tertiary)
                                Text(binding.moduleIdentifier)
                                    .font(.subheadline.bold())
                            }
                            HStack(spacing: 8) {
                                Text(binding.bindingType.rawValue)
                                    .font(.system(size: 8, weight: .medium))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1), in: Capsule())
                                    .foregroundStyle(Color.accentColor)
                                Text(binding.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        Circle()
                            .fill(binding.isActive ? Color.green : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                let ids = offsets.map { filteredBindings[$0].id }
                ids.forEach { binder.unbind(bindingID: $0) }
            }
        } header: {
            Text("Bindings (\(filteredBindings.count))")
        }
    }

    private var templatesSection: some View {
        Section {
            ForEach(binder.templates.prefix(3)) { template in
                HStack {
                    Image(systemName: template.iconName)
                        .font(.title3).foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name).font(.subheadline.bold())
                        Text(template.description).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    Text(template.category)
                        .font(.system(size: 8)).foregroundStyle(.tertiary)
                }
            }
            if binder.templates.count > 3 {
                Button("Browse All Templates (\(binder.templates.count))") { showingTemplates = true }
                    .font(.caption)
            }
        } header: {
            Text("Connector Templates")
        }
    }

    private var streamsSection: some View {
        Section {
            if binder.liveStreams.isEmpty {
                Text("No active data streams.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(binder.liveStreams.filter(\.value).keys), id: \.self) { connID in
                    HStack {
                        Image(systemName: "bolt.horizontal.fill")
                            .foregroundStyle(.green)
                        Text(connectorName(for: connID)).font(.caption.bold())
                        Spacer()
                        Button("Stop") { binder.stopLiveStream(connectorID: connID) }
                            .font(.caption).buttonStyle(.bordered).controlSize(.mini)
                    }
                }
            }
        } header: {
            Text("Live Data Streams")
        }
    }

    private var actionsSection: some View {
        Section {
            Button { showingAddBinding = true } label: {
                Label("Create Binding", systemImage: "plus.circle.fill")
            }
            Button { showingTemplates = true } label: {
                Label("Browse Templates", systemImage: "doc.on.doc")
            }
        } header: {
            Text("Actions")
        }
    }

    @State private var selectedConnectorID: UUID?
    @State private var selectedModuleID: String = ""
    @State private var selectedBindingType: ConnectorBinding.BindingType = .dataSource

    private var addBindingSheet: some View {
        Form {
            Section("Connector") {
                Picker("Connector", selection: $selectedConnectorID) {
                    Text("Select...").tag(nil as UUID?)
                    ForEach(connectorManager.connectors, id: \.id) { connector in
                        Text(connector.name).tag(connector.id as UUID?)
                    }
                }
            }
            Section("Module") {
                Picker("Module", selection: $selectedModuleID) {
                    Text("Select...").tag("")
                    ForEach(moduleRegistry.modules) { mod in
                        Text(mod.displayName).tag(mod.identifier)
                    }
                }
            }
            Section("Binding Type") {
                Picker("Type", selection: $selectedBindingType) {
                    ForEach(ConnectorBinding.BindingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Create Binding")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddBinding = false } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    if let connID = selectedConnectorID, !selectedModuleID.isEmpty {
                        _ = try? binder.bind(connectorID: connID, to: selectedModuleID, type: selectedBindingType)
                    }
                    showingAddBinding = false
                }
                .disabled(selectedConnectorID == nil || selectedModuleID.isEmpty)
            }
        }
    }

    private var templateBrowserSheet: some View {
        List {
            ForEach(binder.templates) { template in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: template.iconName)
                            .font(.title2).foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading) {
                            Text(template.name).font(.subheadline.bold())
                            Text(template.description).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    HStack(spacing: 12) {
                        Label(template.authMethod.rawValue, systemImage: "lock").font(.caption2)
                        Label(template.category, systemImage: "tag").font(.caption2)
                        Label("\(template.defaultEndpoints.count) endpoints", systemImage: "network").font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Connector Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Done") { showingTemplates = false } }
        }
    }

    @ViewBuilder
    private func bindingDetailSheet(_ binding: ConnectorBinding) -> some View {
        List {
            Section("Binding Details") {
                LabeledContent("Connector", value: connectorName(for: binding.connectorID))
                LabeledContent("Module", value: binding.moduleIdentifier)
                LabeledContent("Type", value: binding.bindingType.rawValue)
                LabeledContent("Active", value: binding.isActive ? "Yes" : "No")
                LabeledContent("Created", value: binding.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            if !binding.configuration.isEmpty {
                Section("Configuration") {
                    ForEach(Array(binding.configuration.keys.sorted()), id: \.self) { key in
                        LabeledContent(key, value: binding.configuration[key] ?? "")
                    }
                }
            }
            Section("Stream") {
                if binder.liveStreams[binding.connectorID] == true {
                    Button("Stop Live Stream") { binder.stopLiveStream(connectorID: binding.connectorID) }
                } else {
                    Button("Start Live Stream") { binder.startLiveStream(connectorID: binding.connectorID) }
                }
            }
            Section {
                Button("Remove Binding", role: .destructive) {
                    binder.unbind(bindingID: binding.id)
                    selectedBinding = nil
                }
            }
        }
        .navigationTitle("Binding Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Done") { selectedBinding = nil } }
        }
    }

    private func connectorName(for id: UUID) -> String {
        connectorManager.connectors.first(where: { $0.id == id })?.name ?? id.uuidString.prefix(8).description
    }
}
