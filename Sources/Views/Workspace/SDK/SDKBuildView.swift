import SwiftUI

struct SDKBuildView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var toolManager = SDKToolManager.shared
    @StateObject private var policyEngine = SDKPolicyEngine.shared

    @State private var isBuilding = false
    @State private var buildProgress: Double = 0.0
    @State private var exportedURL: URL?
    @State private var errorMessage: String?

    @State private var buildMode: BuildMode = .debug
    @State private var targetPlatform: TargetPlatform = .iOS
    @State private var includeTests = false
    @State private var verboseLogging = false
    @State private var cleanBuildEnabled = false
    @State private var codeSigningEnabled = true
    @State private var optimizeAssets = true
    @State private var parallelBuild = true

    @State private var showingConsole = false
    @State private var showingSystemExplorer = false
    @State private var showingMetadataSheet = false
    @State private var showingConfigSheet = false

    @State private var metadataName = ""
    @State private var metadataDescription = ""
    @State private var metadataStatus: SDKProject.ProjectStatus = .draft

    enum BuildMode: String, CaseIterable {
        case debug = "Debug", release = "Release", profile = "Profile"
    }

    enum TargetPlatform: String, CaseIterable {
        case iOS, macOS, watchOS, tvOS, multiPlatform = "Multi Platform"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let project = projectManager.currentProject {
                    headerSection(project)

                    SDKSectionHeader(title: "Build Pipeline", subtext: "Configure and execute project builds.")

                    SDKModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                buildOptionPill(title: buildMode.rawValue, icon: "hammer.fill")
                                buildOptionPill(title: "\(targetPlatform)", icon: "iphone")
                                Spacer()
                                Button { showingConfigSheet = true } label: {
                                    Image(systemName: "slider.horizontal.3").foregroundStyle(.accent)
                                }
                            }

                            if isBuilding {
                                VStack(spacing: 8) {
                                    ProgressView(value: buildProgress).tint(.accentColor)
                                    Text("Building SDK Artifacts...").font(.caption2.bold()).foregroundStyle(.secondary)
                                }
                            }

                            Button(action: startBuild) {
                                Label(isBuilding ? "Building..." : "Run Build", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isBuilding)
                        }
                    }

                    if let url = exportedURL {
                        SDKModernCard {
                            HStack {
                                Image(systemName: "doc.zipper").font(.title2).foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text("Build Succeeded").font(.subheadline.bold()).sdkSuccessText()
                                    Text(url.lastPathComponent).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                            }
                        }
                    }

                    if let error = errorMessage {
                        SDKModernCard {
                            HStack {
                                Image(systemName: "exclamationmark.octagon.fill").foregroundStyle(.red)
                                Text(error).font(.caption).sdkErrorText()
                                Spacer()
                            }
                        }
                    }

                    SDKSectionHeader(title: "Metrics", subtext: "Runtime and execution analytics.")
                    SDKModernCard {
                        let metrics = telemetry.getMetrics()
                        VStack(spacing: 12) {
                            metricRow(label: "Total Executions", value: "\(metrics.totalTraces)")
                            metricRow(label: "Success / Failure", value: "\(metrics.successCount) / \(metrics.failureCount)", color: metrics.failureCount > 0 ? .orange : .green)
                            metricRow(label: "Avg Latency", value: "\(String(format: "%.1f", metrics.averageDurationMs))ms")
                            metricRow(label: "Log Entries", value: "\(logStore.entries.count)")
                        }
                    }

                    SDKSectionHeader(title: "Configuration", subtext: "Manage project modules and access.")
                    SDKModernCard {
                        VStack(spacing: 0) {
                            Button {
                                metadataName = project.name
                                metadataDescription = project.description
                                metadataStatus = project.status
                                showingMetadataSheet = true
                            } label: {
                                managementRow(title: "Edit Metadata", icon: "pencil.circle", subtitle: "Name, description, and status")
                            }
                            Divider().padding(.vertical, 12)
                            NavigationLink {
                                SDKPermissionControlView(project: Binding(
                                    get: { projectManager.currentProject ?? project },
                                    set: { projectManager.currentProject = $0 }
                                ))
                            } label: {
                                managementRow(title: "Permissions", icon: "lock.shield", subtitle: "API scope control")
                            }
                            Divider().padding(.vertical, 12)
                            NavigationLink { SDKScopesEditorView() } label: {
                                managementRow(title: "Scopes Editor", icon: "lock.shield.fill", subtitle: "Manage system permissions")
                            }
                        }
                    }

                    SDKSectionHeader(title: "Development Tools", subtext: "Advanced debugging and inspection.")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        toolCard(title: "IDE", icon: "square.split.2x2.fill", color: .indigo, destination: SDKWorkspaceContainerView())
                        toolCard(title: "Console", icon: "terminal", color: .teal, destination: SDKActionConsoleView())
                        toolCard(title: "Debug", icon: "ladybug", color: .red, destination: SDKDebugView())
                        toolCard(title: "Logs", icon: "doc.text.magnifyingglass", color: .gray, destination: SDKLogsView())
                    }
                } else {
                    ContentUnavailableView("No Project", systemImage: "hammer", description: Text("Select or create a project to build."))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Build")
        .sheet(isPresented: $showingConfigSheet) {
            NavigationStack { buildConfigForm }.presentationDetents([.medium])
        }
        .sheet(isPresented: $showingMetadataSheet) {
            NavigationStack { metadataSheetContent }.presentationDetents([.medium, .large])
        }
    }

    private func headerSection(_ project: SDKProject) -> some View {
        SDKModernCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(project.name).font(.headline)
                    Spacer()
                    SDKStatusPill(status: project.healthStatus.toSDKStatus(), text: project.healthStatus.rawValue.uppercased())
                }

                HStack(spacing: 20) {
                    statPill(label: "\(project.enabledScopes.count)", caption: "Scopes")
                    statPill(label: "\(project.enabledPluginIDs.count)", caption: "Plugins")
                    statPill(label: "\(project.enabledToolIDs.count)", caption: "Tools")
                    statPill(label: "\(project.enabledConnectorIDs.count)", caption: "Connectors")
                }
            }
        }
    }

    private func buildOptionPill(title: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(title).font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.1), in: Capsule())
        .foregroundStyle(.accent)
    }

    private func metricRow(label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(label).sdkSubtext()
            Spacer()
            Text(value).font(.system(.subheadline, design: .monospaced)).foregroundStyle(color)
        }
    }

    private func managementRow(title: String, icon: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).sdkSubtext()
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func toolCard<D: View>(title: String, icon: String, color: Color, destination: D) -> some View {
        NavigationLink(destination: destination) {
            SDKModernCard {
                VStack(spacing: 8) {
                    Image(systemName: icon).font(.title3).foregroundStyle(color)
                    Text(title).font(.caption.bold())
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private func statPill(label: String, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.subheadline.bold())
            Text(caption).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var buildConfigForm: some View {
        Form {
            Section("Parameters") {
                Picker("Mode", selection: $buildMode) {
                    ForEach(BuildMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("Platform", selection: $targetPlatform) {
                    ForEach(TargetPlatform.allCases, id: \.self) { Text("\($0)").tag($0) }
                }
            }
            Section("Advanced") {
                Toggle("Clean Build", isOn: $cleanBuildEnabled)
                Toggle("Include Tests", isOn: $includeTests)
                Toggle("Verbose Logging", isOn: $verboseLogging)
                Toggle("Code Signing", isOn: $codeSigningEnabled)
                Toggle("Optimize Assets", isOn: $optimizeAssets)
                Toggle("Parallel Build", isOn: $parallelBuild)
            }
        }
        .navigationTitle("Build Configuration")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { showingConfigSheet = false } }
        }
    }

    private var metadataSheetContent: some View {
        Form {
            Section("Identity") {
                TextField("Project Name", text: $metadataName)
                TextField("Description", text: $metadataDescription, axis: .vertical).lineLimit(3...5)
                Picker("Status", selection: $metadataStatus) {
                    ForEach(SDKProject.ProjectStatus.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }
            Section("Assignments") {
                NavigationLink("Scope Assignments") { scopeSelector }
                NavigationLink("Connectors & Tools") { connectorAndToolAssignment }
            }
        }
        .navigationTitle("Project Metadata")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingMetadataSheet = false } }
            ToolbarItem(placement: .confirmationAction) { Button("Save") { saveBuild(); showingMetadataSheet = false } }
        }
    }

    private var scopeSelector: some View {
        List(policyEngine.availableScopes(), id: \.name) { definition in
            Toggle(isOn: Binding(
                get: { projectManager.currentProject?.enabledScopes.contains(definition.name) ?? false },
                set: { isEnabled in
                    guard var project = projectManager.currentProject else { return }
                    if isEnabled {
                        if !project.enabledScopes.contains(definition.name) { project.enabledScopes.append(definition.name) }
                    } else {
                        project.enabledScopes.removeAll { $0 == definition.name }
                    }
                    projectManager.updateProject(project)
                }
            )) {
                VStack(alignment: .leading) {
                    Text(definition.name).font(.subheadline)
                    Text(definition.riskLevel.rawValue.capitalized).sdkSubtext()
                }
            }
        }
        .navigationTitle("Scopes")
    }

    private var connectorAndToolAssignment: some View {
        List {
            Section("Connectors") {
                ForEach(connectorManager.connectors, id: \.id) { connector in
                    Toggle(connector.name, isOn: Binding(
                        get: { projectManager.currentProject?.enabledConnectorIDs.contains(connector.id) ?? false },
                        set: { enabled in
                            guard var project = projectManager.currentProject else { return }
                            if enabled {
                                if !project.enabledConnectorIDs.contains(connector.id) { project.enabledConnectorIDs.append(connector.id) }
                            } else {
                                project.enabledConnectorIDs.removeAll { $0 == connector.id }
                            }
                            projectManager.updateProject(project)
                        }
                    ))
                }
            }
            Section("Tools") {
                ForEach(toolManager.tools, id: \.id) { tool in
                    Toggle(tool.name, isOn: Binding(
                        get: { projectManager.currentProject?.enabledToolIDs.contains(tool.id) ?? false },
                        set: { enabled in
                            guard var project = projectManager.currentProject else { return }
                            if enabled {
                                if !project.enabledToolIDs.contains(tool.id) { project.enabledToolIDs.append(tool.id) }
                            } else {
                                project.enabledToolIDs.removeAll { $0 == tool.id }
                            }
                            projectManager.updateProject(project)
                        }
                    ))
                }
            }
        }
        .navigationTitle("Assignments")
    }

    private func saveBuild() {
        guard var project = projectManager.currentProject else { return }
        project.name = metadataName
        project.description = metadataDescription
        project.status = metadataStatus
        project.updatedAt = Date()
        project.version += 1
        projectManager.updateProject(project)
        try? projectManager.save()
        SDKLogStore.shared.log("Project saved: \(project.name)", source: "SDKBuildView", level: .info)
    }

    private func startBuild() {
        guard let project = projectManager.currentProject else { return }
        isBuilding = true
        errorMessage = nil
        exportedURL = nil
        Task {
            await MainActor.run { buildProgress = 0.1 }
            do {
                if cleanBuildEnabled { SDKDataEngine.shared.invalidateCache() }
                let config = SDKExportConfig(
                    projectName: project.name,
                    scopes: project.enabledScopes.compactMap { s in SDKScope.allCases.first { "\($0)" == s } },
                    pluginIDs: project.enabledPluginIDs,
                    toolIDs: project.enabledToolIDs,
                    connectorIDs: project.enabledConnectorIDs,
                    automationRules: project.automationRules,
                    exportedAt: Date()
                )
                await MainActor.run { buildProgress = 0.6 }
                let url = try await SDKExportService().export(config: config)
                await MainActor.run {
                    buildProgress = 1.0
                    self.exportedURL = url
                    self.isBuilding = false
                    var updated = project
                    updated.lastBuiltAt = Date()
                    projectManager.updateProject(updated)
                    try? projectManager.save()
                }
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription; self.isBuilding = false }
            }
        }
    }
}
