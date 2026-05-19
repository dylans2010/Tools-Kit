import SwiftUI

struct SDKBuildView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var toolManager = SDKToolManager.shared
    @StateObject private var policyEngine = SDKPolicyEngine.shared
    @StateObject private var authorizationManager = AuthorizationManager.shared

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
    @State private var metadataName = ""
    @State private var metadataDescription = ""
    @State private var metadataStatus: SDKProject.ProjectStatus = .draft

    enum BuildMode: String, CaseIterable { case debug = "Debug", release = "Release", profile = "Profile" }
    enum TargetPlatform: String, CaseIterable { case iOS, macOS, watchOS, tvOS, multiPlatform = "Multi Platform" }

    var body: some View {
        List {
            if let project = projectManager.currentProject {
                projectOverviewSection(project)
                buildConfigSection
                buildActionsSection
                buildResultSection
                metricsSection
                developmentSection
                sdkSystemsSection
                sdkAssetsSection
                architectureSection(project)
                stabilitySection
                explorationSection
                deploymentSection(project)
            } else {
                emptyProjectSection
            }
        }
        .navigationTitle("Build")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "shippingbox.fill").foregroundStyle(Color.accentColor)
            }
        }
        .sheet(isPresented: $showingConsole) { NavigationStack { SDKConsoleView() } }
        .sheet(isPresented: $showingSystemExplorer) { NavigationStack { SDKSystemExplorerView() } }
        .sheet(isPresented: $showingMetadataSheet) {
            NavigationStack { metadataSheet }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear { loadMetadata() }
    }

    // MARK: - Project Overview

    @ViewBuilder
    private func projectOverviewSection(_ project: SDKProject) -> some View {
        Section("Project Overview") {
            LabeledContent("Project", value: project.name)
            LabeledContent("Version", value: "v\(project.version)")
            LabeledContent("Health") {
                Text(project.healthStatus.rawValue.capitalized)
                    .foregroundStyle(healthColor(project.healthStatus))
            }
            HStack {
                LabeledContent("Scopes", value: "\(project.enabledScopes.count)")
                LabeledContent("Plugins", value: "\(project.enabledPluginIDs.count)")
            }
            HStack {
                LabeledContent("Tools", value: "\(project.enabledToolIDs.count)")
                LabeledContent("Links", value: "\(project.enabledConnectorIDs.count)")
            }
            LabeledContent("Authorization", value: authorizationManager.authState.rawValue)

            if isBuilding {
                buildProgressView
            }

            Button {
                loadMetadata()
                showingMetadataSheet = true
            } label: {
                Label("Edit Metadata", systemImage: "slider.horizontal.3")
            }
        }
    }

    private var buildProgressView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Building...").font(.caption.bold())
                Spacer()
                Text("\(Int(buildProgress * 100))%").font(.caption.monospaced())
            }
            ProgressView(value: buildProgress)
        }
    }

    // MARK: - Build Configuration

    private var buildConfigSection: some View {
        Section("Configuration") {
            Picker("Mode", selection: $buildMode) {
                ForEach(BuildMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            Picker("Platform", selection: $targetPlatform) {
                ForEach(TargetPlatform.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            Toggle("Clean Build", isOn: $cleanBuildEnabled)
            Toggle("Include Tests", isOn: $includeTests)
            Toggle("Code Signing", isOn: $codeSigningEnabled)
            Toggle("Optimize Assets", isOn: $optimizeAssets)
            Toggle("Parallel Build", isOn: $parallelBuild)
            Toggle("Verbose Logging", isOn: $verboseLogging)
        }
    }

    // MARK: - Build Actions

    private var buildActionsSection: some View {
        Section("Build Pipeline") {
            Button(action: startBuild) {
                HStack {
                    Label("Execute Pipeline", systemImage: "hammer.fill")
                    Spacer()
                    if isBuilding { ProgressView().controlSize(.small) }
                }
            }
            .disabled(isBuilding)

            Button(action: validateProject) {
                Label("Run Validation", systemImage: "checkmark.seal.fill")
            }
            .disabled(isBuilding)

            Button(action: cleanBuildCache) {
                Label("Clean Artifacts", systemImage: "trash.fill")
            }
            .disabled(isBuilding)
        }
    }

    // MARK: - Build Result

    @ViewBuilder
    private var buildResultSection: some View {
        if let url = exportedURL {
            Section("Build Result") {
                Label("Build successful", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                HStack {
                    Image(systemName: "doc.zipper")
                    VStack(alignment: .leading) {
                        Text(url.lastPathComponent).font(.subheadline.bold())
                        Text("Size: \(fileSizeString(url))").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                }
            }
        }

        if let error = errorMessage {
            Section("Pipeline Failure") {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        Section("Build Metrics") {
            let metrics = telemetry.getMetrics()
            LabeledContent("Total Executions", value: "\(metrics.totalTraces)")
            LabeledContent("Success / Failure") {
                Text("\(metrics.successCount) / \(metrics.failureCount)")
                    .foregroundStyle(metrics.failureCount > 0 ? Color.orange : Color.green)
            }
            LabeledContent("Avg Latency", value: "\(String(format: "%.1f", metrics.averageDurationMs))ms")
            LabeledContent("Log Entries", value: "\(logStore.entries.count)")
        }
    }

    // MARK: - Development

    private var developmentSection: some View {
        Section("Development") {
            NavigationLink(destination: SDKWorkspaceContainerView()) { Label("IDE Workspace", systemImage: "macwindow.on.rectangle") }
            NavigationLink(destination: SDKActionConsoleView()) { Label("Action Console", systemImage: "terminal") }
            Button { showingConsole = true } label: { Label("Console Output", systemImage: "list.bullet.rectangle.portrait") }
            NavigationLink(destination: SDKDebugView()) { Label("Debug Inspector", systemImage: "ladybug.fill") }
            NavigationLink(destination: SDKLogsView()) { Label("System Logs", systemImage: "doc.text.magnifyingglass") }
            NavigationLink(destination: SDKEventStreamView()) { Label("Event Stream", systemImage: "waveform.path.ecg.rectangle") }
            NavigationLink(destination: DevToolsMainView()) { Label("Dev Tools", systemImage: "hammer.fill") }
        }
    }

    // MARK: - SDK Systems

    private var sdkSystemsSection: some View {
        Section("SDK Systems") {
            NavigationLink("SDK Download & Export", destination: SDKDownloadView())
            NavigationLink("Import Custom App", destination: CustomAppSDKView())
            NavigationLink("AI Help Assistant", destination: SDKHelpView())
            NavigationLink("AI App Builder", destination: SDKSupportView())
            NavigationLink("Developer Guide", destination: SDKDeveloperGuideView())
            NavigationLink("Module Registry", destination: SDKModuleRegistryView())
            NavigationLink("Plugin Lifecycle", destination: SDKPluginLifecycleView())
            NavigationLink("Connector Bindings", destination: SDKConnectorBindingView())
        }
    }

    // MARK: - SDK Assets

    private var sdkAssetsSection: some View {
        Section("SDK Assets") {
            NavigationLink("Package Dependencies", destination: PackageDependenciesView())
            NavigationLink("Library Management", destination: LibraryManageView())
            NavigationLink("Framework Management", destination: FrameworkManageView())
        }
    }

    // MARK: - Architecture

    @ViewBuilder
    private func architectureSection(_ project: SDKProject) -> some View {
        Section("Architecture") {
            NavigationLink("Permissions") {
                SDKPermissionControlView(project: Binding(
                    get: { projectManager.currentProject ?? project },
                    set: { projectManager.currentProject = $0 }
                ))
            }
            NavigationLink("Authorization", destination: SignInView())
            NavigationLink("Automation", destination: SDKAutomationView())
            NavigationLink("Flow Builder") {
                SDKFlowBuilderView(project: Binding(
                    get: { projectManager.currentProject ?? project },
                    set: { projectManager.currentProject = $0 }
                ))
            }
            NavigationLink("Plugins", destination: SDKPluginsView())
            NavigationLink("Tools", destination: SDKToolsView())
        }
    }

    // MARK: - Stability

    private var stabilitySection: some View {
        Section("Stability") {
            NavigationLink("Diagnostics", destination: SDKDiagnosticsView())
            NavigationLink("Security Monitor", destination: SDKSecurityMonitorView())
            NavigationLink("Control Center", destination: SDKControlCenterView())
            NavigationLink("Data Control", destination: SDKDataControlView())
        }
    }

    // MARK: - Exploration

    private var explorationSection: some View {
        Section("Exploration") {
            Button("System Explorer") { showingSystemExplorer = true }
            NavigationLink("Workspace Explorer", destination: SDKWorkspaceExplorerView())
            NavigationLink("API Browser", destination: SDKAPIBrowserView())
        }
    }

    // MARK: - Deployment

    @ViewBuilder
    private func deploymentSection(_ project: SDKProject) -> some View {
        Section("Build & Deploy") {
            NavigationLink("Integration Tests", destination: SDKIntegrationTestView())
            NavigationLink("App Builder", destination: SDKAppBuilderView())
            NavigationLink("Deployment", destination: SDKDeploymentView(project: project))
        }
    }

    // MARK: - Empty State

    private var emptyProjectSection: some View {
        Section {
            ContentUnavailableView {
                Label("No Project", systemImage: "hammer.circle")
            } description: {
                Text("Create an SDK project to configure scopes, connectors, tools, and builds.")
            } actions: {
                Button("Create Project") {
                    let project = projectManager.createProject(name: "New SDK Project", status: .draft)
                    metadataName = project.name
                    metadataDescription = project.description
                    metadataStatus = project.status
                    showingMetadataSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Metadata Sheet

    private var metadataSheet: some View {
        Form {
            Section("Project Info") {
                TextField("Project Name", text: $metadataName)
                TextField("Description", text: $metadataDescription, axis: .vertical)
                    .lineLimit(3...5)
                Picker("Status", selection: $metadataStatus) {
                    ForEach(SDKProject.ProjectStatus.allCases, id: \.self) {
                        Text($0.rawValue.capitalized).tag($0)
                    }
                }
            }
            Section("Access Scopes") { scopeSelector }
            Section("Assignments") { connectorAndToolAssignment }
        }
        .navigationTitle("Project Metadata")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showingMetadataSheet = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveBuild(); showingMetadataSheet = false }
            }
        }
    }

    // MARK: - Helpers

    private func loadMetadata() {
        guard let project = projectManager.currentProject else { return }
        metadataName = project.name
        metadataDescription = project.description
        metadataStatus = project.status
    }

    private func healthColor(_ status: HealthStatus) -> Color {
        switch status {
        case .healthy: .green
        case .degraded: .yellow
        case .critical: .red
        case .unknown: .gray
        }
    }

    private func fileSizeString(_ url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? UInt64 else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private func log(_ message: String, level: SDKLogStore.LogLevel = .info) {
        guard verboseLogging else { return }
        SDKLogStore.shared.log(message, source: "SDKBuildView", level: level)
    }

    // MARK: - Build Functions

    private func startBuild() {
        guard let project = projectManager.currentProject else { return }
        isBuilding = true
        errorMessage = nil
        exportedURL = nil
        log("Build Started: \(buildMode.rawValue) | \(targetPlatform.rawValue)")

        Task {
            await MainActor.run { buildProgress = 0.1 }

            do {
                if cleanBuildEnabled {
                    SDKDataEngine.shared.invalidateCache()
                    await MainActor.run { buildProgress = 0.2 }
                    log("Cache invalidated for clean build")
                }

                await MainActor.run { buildProgress = 0.3 }

                let config = SDKExportConfig(
                    projectName: project.name,
                    scopes: project.enabledScopes.compactMap { scopeStr in
                        SDKScope.allCases.first { String(describing: $0) == scopeStr }
                    },
                    pluginIDs: project.enabledPluginIDs,
                    toolIDs: project.enabledToolIDs,
                    connectorIDs: project.enabledConnectorIDs,
                    automationRules: project.automationRules,
                    exportedAt: Date()
                )

                await MainActor.run { buildProgress = 0.6 }

                if includeTests {
                    log("Running pre build validation...")
                    await MainActor.run { buildProgress = 0.7 }
                }

                let url = try await SDKExportService().export(config: config)
                await MainActor.run {
                    buildProgress = 1.0
                    exportedURL = url
                    isBuilding = false
                    projectManager.currentProject?.lastBuiltAt = Date()
                    try? projectManager.save()
                    log("Build Completed: \(url.lastPathComponent)")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isBuilding = false
                    log("Build Failed: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    private func quickBuild() {
        guard projectManager.currentProject != nil else { return }
        isBuilding = true
        errorMessage = nil
        SDKLogStore.shared.log("Quick Build Started", source: "SDKBuildView", level: .info)

        Task {
            await MainActor.run { buildProgress = 0.5 }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                buildProgress = 1.0
                isBuilding = false
                projectManager.currentProject?.lastBuiltAt = Date()
                try? projectManager.save()
                SDKLogStore.shared.log("Quick Build Completed", source: "SDKBuildView", level: .info)
            }
        }
    }

    private func validateProject() {
        guard let project = projectManager.currentProject else { return }
        var issues: [String] = []
        if project.enabledScopes.isEmpty { issues.append("No Scopes Enabled") }
        if project.enabledPluginIDs.isEmpty { issues.append("No Plugins Selected") }
        if project.enabledToolIDs.isEmpty { issues.append("No Tools Selected") }

        if issues.isEmpty {
            SDKLogStore.shared.log("Project Validation Passed", source: "SDKBuildView", level: .info)
            errorMessage = nil
        } else {
            let msg = "Validation warnings: " + issues.joined(separator: ", ")
            SDKLogStore.shared.log(msg, source: "SDKBuildView", level: .warning)
            errorMessage = msg
        }
    }

    private func cleanBuildCache() {
        SDKDataEngine.shared.invalidateCache()
        SDKLogStore.shared.log("Build cache cleaned", source: "SDKBuildView", level: .info)
    }

    // MARK: - Scope & Assignment Selectors

    private var scopeSelector: some View {
        ForEach(policyEngine.availableScopes(), id: \.name) { definition in
            Toggle(isOn: Binding(
                get: { projectManager.currentProject?.enabledScopes.contains(definition.name) ?? false },
                set: { isEnabled in
                    guard var project = projectManager.currentProject else { return }
                    if isEnabled {
                        if !project.enabledScopes.contains(definition.name) { project.enabledScopes.append(definition.name) }
                    } else {
                        project.enabledScopes.removeAll { $0 == definition.name }
                    }
                    projectManager.currentProject = project
                }
            )) {
                HStack {
                    Text(definition.name).font(.caption)
                    Spacer()
                    Text(definition.riskLevel.rawValue.capitalized).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var connectorAndToolAssignment: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connectors").font(.caption).foregroundStyle(.secondary)
            ForEach(connectorManager.connectors, id: \.id) { connector in
                Toggle(connector.name, isOn: toggleBinding(for: connector.id, keyPath: \.enabledConnectorIDs))
            }
            Text("Tools").font(.caption).foregroundStyle(.secondary)
            ForEach(toolManager.tools, id: \.id) { tool in
                Toggle(tool.name, isOn: toggleBinding(for: tool.id, keyPath: \.enabledToolIDs))
            }
        }
    }

    private func toggleBinding(for id: String, keyPath: WritableKeyPath<SDKProject, [String]>) -> Binding<Bool> {
        Binding(
            get: { projectManager.currentProject?[keyPath: keyPath].contains(id) ?? false },
            set: { enabled in
                guard var project = projectManager.currentProject else { return }
                if enabled {
                    if !project[keyPath: keyPath].contains(id) { project[keyPath: keyPath].append(id) }
                } else {
                    project[keyPath: keyPath].removeAll { $0 == id }
                }
                projectManager.currentProject = project
            }
        )
    }

    private func saveBuild() {
        guard var project = projectManager.currentProject else { return }
        guard !metadataName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Project name is required."
            return
        }
        project.name = metadataName
        project.description = metadataDescription
        project.status = metadataStatus
        let selectedDefinitions = policyEngine.availableScopes().filter { project.enabledScopes.contains($0.name) }
        if selectedDefinitions.contains(where: { $0.requiresJustification }) &&
            metadataDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Description/justification is required for high-risk scopes."
            return
        }
        project.updatedAt = Date()
        project.version += 1
        projectManager.updateProject(project)
        projectManager.currentProject = project
        errorMessage = nil
        SDKLogStore.shared.log("Build configuration saved (v\(project.version))", source: "SDKBuildView", level: .info)
    }
}
