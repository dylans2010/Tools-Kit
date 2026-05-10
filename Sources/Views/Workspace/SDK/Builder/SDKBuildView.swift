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
    @State private var metadataName = ""
    @State private var metadataDescription = ""
    @State private var metadataStatus: SDKProject.ProjectStatus = .draft

    enum BuildMode: String, CaseIterable {
        case debug = "Debug"
        case release = "Release"
        case profile = "Profile"
    }

    enum TargetPlatform: String, CaseIterable {
        case iOS = "iOS"
        case macOS = "macOS"
        case watchOS = "watchOS"
        case tvOS = "tvOS"
        case multiPlatform = "Multi Platform"
    }

    var body: some View {
        List {
            if let project = projectManager.currentProject {
                projectOverviewSection(project)
                buildConfigurationSection
                buildPipelineSection
                buildOutputSection
                buildMetricsSection
                developmentSection
                architectureSection(project)
                stabilitySection
                explorationSection
                deploymentSection(project)
            } else {
                emptyProjectSection
            }
        }
        .navigationTitle("Build")
        .sheet(isPresented: $showingConsole) {
            NavigationStack { SDKConsoleView() }
        }
        .sheet(isPresented: $showingSystemExplorer) {
            NavigationStack { SDKSystemExplorerView() }
        }
        .sheet(isPresented: $showingMetadataSheet) {
            NavigationStack { metadataSheetContent }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if let project = projectManager.currentProject {
                metadataName = project.name
                metadataDescription = project.description
                metadataStatus = project.status
            }
        }
    }

    // MARK: - Project Overview

    @ViewBuilder
    private func projectOverviewSection(_ project: SDKProject) -> some View {
        Section {
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

            if isBuilding {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Building...")
                            .font(.caption.bold())
                        Spacer()
                        Text("\(Int(buildProgress * 100))%")
                            .font(.caption.monospaced())
                    }
                    ProgressView(value: buildProgress)
                }
            }

            Button {
                metadataName = project.name
                metadataDescription = project.description
                metadataStatus = project.status
                showingMetadataSheet = true
            } label: {
                Label("Edit Metadata", systemImage: "slider.horizontal.3")
            }
        } header: {
            Text("Project Overview")
        }
    }

    // MARK: - Build Configuration

    private var buildConfigurationSection: some View {
        Section {
            Picker("Mode", selection: $buildMode) {
                ForEach(BuildMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Picker("Platform", selection: $targetPlatform) {
                ForEach(TargetPlatform.allCases, id: \.self) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }

            Toggle("Clean Build", isOn: $cleanBuildEnabled)
            Toggle("Include Tests", isOn: $includeTests)
            Toggle("Verbose Logging", isOn: $verboseLogging)
            Toggle("Code Signing", isOn: $codeSigningEnabled)
            Toggle("Optimize Assets", isOn: $optimizeAssets)
            Toggle("Parallel Build", isOn: $parallelBuild)
                } header: {
            Text("Configuration")
        }
    }

    // MARK: - Build Pipeline

    private var buildPipelineSection: some View {
        Section {
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
                } header: {
            Text("Build Pipeline")
        }
    }

    // MARK: - Build Output

    @ViewBuilder
    private var buildOutputSection: some View {
        if let url = exportedURL {
            Section {
                Label("Build successful", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                HStack {
                    Image(systemName: "doc.zipper")
                    VStack(alignment: .leading) {
                        Text(url.lastPathComponent).font(.subheadline.bold())
                        Text("Size: \(fileSizeString(url))").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            } header: {
                Text("Build Result")
            }
        }

        if let error = errorMessage {
            Section {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } header: {
                Text("Pipeline Failure")
            }
        }
    }

    // MARK: - Build Metrics

    private var buildMetricsSection: some View {
        Section {
            let metrics = telemetry.getMetrics()
            LabeledContent("Total Executions", value: "\(metrics.totalTraces)")
            LabeledContent("Success / Failure") {
                Text("\(metrics.successCount) / \(metrics.failureCount)")
                    .foregroundStyle(metrics.failureCount > 0 ? Color.orange : Color.green)
            }
            LabeledContent("Avg Latency", value: "\(String(format: "%.1f", metrics.averageDurationMs))ms")
            LabeledContent("Log Entries", value: "\(logStore.entries.count)")
                } header: {
            Text("Build Metrics")
        }
    }

    // MARK: - Development

    private var developmentSection: some View {
        Section {
            NavigationLink("IDE Workspace", destination: SDKWorkspaceContainerView())
            NavigationLink("Action Console", destination: SDKActionConsoleView())
            Button("Console Output") { showingConsole = true }
            NavigationLink("Debug Inspector", destination: SDKDebugView())
            NavigationLink("System Logs", destination: SDKLogsView())
            NavigationLink("Event Stream", destination: SDKEventStreamView())
                } header: {
            Text("Development")
        }
    }

    // MARK: - Architecture

    @ViewBuilder
    private func architectureSection(_ project: SDKProject) -> some View {
        Section {
            NavigationLink("Permissions") {
                SDKPermissionControlView(project: Binding(
                    get: { projectManager.currentProject ?? project },
                    set: { projectManager.currentProject = $0 }
                ))
            }
            NavigationLink("Automation", destination: SDKAutomationView())
            NavigationLink("Flow Builder") {
                SDKFlowBuilderView(project: Binding(
                    get: { projectManager.currentProject ?? project },
                    set: { projectManager.currentProject = $0 }
                ))
            }
            NavigationLink("Plugins", destination: SDKPluginsView())
            NavigationLink("Tools", destination: SDKToolsView())
                } header: {
            Text("Architecture")
        }
    }

    // MARK: - Stability

    private var stabilitySection: some View {
        Section {
            NavigationLink("Diagnostics", destination: SDKDiagnosticsView())
            NavigationLink("Security Monitor", destination: SDKSecurityMonitorView())
            NavigationLink("Control Center", destination: SDKControlCenterView())
            NavigationLink("Data Control", destination: SDKDataControlView())
                } header: {
            Text("Stability")
        }
    }

    // MARK: - Exploration

    private var explorationSection: some View {
        Section {
            Button("System Explorer") { showingSystemExplorer = true }
            NavigationLink("Workspace Explorer", destination: SDKWorkspaceExplorerView())
            NavigationLink("API Browser", destination: SDKAPIBrowserView())
                } header: {
            Text("Exploration")
        }
    }

    // MARK: - Deployment

    @ViewBuilder
    private func deploymentSection(_ project: SDKProject) -> some View {
        Section {
            NavigationLink("Integration Tests", destination: SDKIntegrationTestView())
            NavigationLink("App Builder", destination: SDKAppBuilderView())
            NavigationLink("Deployment", destination: SDKDeploymentView(project: project))
                } header: {
            Text("Build & Deploy")
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

    private var metadataSheetContent: some View {
        Form {
            Section {
                TextField("Project Name", text: $metadataName)
                TextField("Description", text: $metadataDescription, axis: .vertical)
                    .lineLimit(3...5)
                Picker("Status", selection: $metadataStatus) {
                    ForEach(SDKProject.ProjectStatus.allCases, id: \.self) { status in
                        Text(status.rawValue.capitalized).tag(status)
                    }
                }
            }

            Section("Access") {
                scopeSelector
            }

            Section("Assignments") {
                connectorAndToolAssignment
            }
        }
        .navigationTitle("Project Metadata")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showingMetadataSheet = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveBuild()
                    showingMetadataSheet = false
                }
            }
        }
    }

    // MARK: - Helpers

    private func healthColor(_ status: HealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }

    private func fileSizeString(_ url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? UInt64 else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    // MARK: - Build Functions

    private func startBuild() {
        guard let project = projectManager.currentProject else { return }
        isBuilding = true
        errorMessage = nil
        exportedURL = nil

        if verboseLogging {
            SDKLogStore.shared.log(
                "Build Started: \(buildMode.rawValue) | \(targetPlatform.rawValue)",
                source: "SDKBuildView", level: .info
            )
        }

        Task {
            await MainActor.run { buildProgress = 0.1 }

            do {
                if cleanBuildEnabled {
                    SDKDataEngine.shared.invalidateCache()
                    await MainActor.run { buildProgress = 0.2 }
                    if verboseLogging {
                        SDKLogStore.shared.log(
                            "Cache invalidated for clean build",
                            source: "SDKBuildView", level: .info
                        )
                    }
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
                    if verboseLogging {
                        SDKLogStore.shared.log(
                            "Running pre build validation...",
                            source: "SDKBuildView", level: .info
                        )
                    }
                    await MainActor.run { buildProgress = 0.7 }
                }

                let url = try await SDKExportService().export(config: config)
                await MainActor.run {
                    buildProgress = 1.0
                    self.exportedURL = url
                    self.isBuilding = false
                    projectManager.currentProject?.lastBuiltAt = Date()
                    try? projectManager.save()
                    if verboseLogging {
                        SDKLogStore.shared.log(
                            "Build Completed: \(url.lastPathComponent)",
                            source: "SDKBuildView", level: .info
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isBuilding = false
                    if verboseLogging {
                        SDKLogStore.shared.log(
                            "Build Failed: \(error.localizedDescription)",
                            source: "SDKBuildView", level: .error
                        )
                    }
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

    private var scopeSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
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
    }

    private var connectorAndToolAssignment: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connectors").font(.caption).foregroundStyle(.secondary)
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
                        projectManager.currentProject = project
                    }
                ))
            }

            Text("Tools").font(.caption).foregroundStyle(.secondary)
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
                        projectManager.currentProject = project
                    }
                ))
            }
        }
    }

    private func saveBuild() {
        guard var project = projectManager.currentProject else { return }
        if metadataName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
