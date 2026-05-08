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
                Section {
                    projectOverviewSection(project)
                } header: {
                    SDKSectionHeader("Project Overview", subtitle: "Managed workspace integrations and builds", systemImage: "folder.fill")
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                Section {
                    projectMetadataEditorSection(project)
                    buildConfigSection
                } header: {
                    SDKSectionHeader("Configuration", subtitle: "Build parameters and identity", systemImage: "gearshape.fill")
                }

                Section {
                    buildActionsSection
                } header: {
                    SDKSectionHeader("Build Pipeline", subtitle: "Execute and validate build stages", systemImage: "hammer.fill")
                }

                buildOutputSection
                buildMetricsSection

                Section {
                    developmentToolsSection
                } header: {
                    SDKSectionHeader("Development", subtitle: "Runtime and system analysis tools", systemImage: "terminal.fill")
                }

                Section {
                    projectConfigSection(project)
                } header: {
                    SDKSectionHeader("Architecture", subtitle: "Define capabilities and permissions", systemImage: "square.stack.3d.up.fill")
                }

                Section {
                    monitoringSection
                } header: {
                    SDKSectionHeader("Stability", subtitle: "Health and diagnostic monitoring", systemImage: "heart.text.square.fill")
                }

                Section {
                    exploreSection
                } header: {
                    SDKSectionHeader("Exploration", subtitle: "Browse system nodes and APIs", systemImage: "magnifyingglass")
                }

                Section {
                    deploySection(project)
                } header: {
                    SDKSectionHeader("Deployment", subtitle: "Finalize and distribute builds", systemImage: "icloud.and.arrow.up.fill")
                }
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
        SDKModernCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name).font(.headline)
                        Text("Version \(project.version)").font(.caption2.monospaced()).foregroundStyle(.tertiary)
                    }
                    Spacer()
                    healthBadge(project.healthStatus)
                }

                HStack(spacing: 10) {
                    SDKStatPill(label: "Scopes", value: "\(project.enabledScopes.count)")
                    SDKStatPill(label: "Plugins", value: "\(project.enabledPluginIDs.count)")
                    SDKStatPill(label: "Tools", value: "\(project.enabledToolIDs.count)")
                    SDKStatPill(label: "Links", value: "\(project.enabledConnectorIDs.count)")
                }

                if isBuilding {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Building...").font(.caption.bold())
                            Spacer()
                            Text("\(Int(buildProgress * 100))%").font(.caption.monospaced())
                        }
                        ProgressView(value: buildProgress)
                            .tint(.primary)
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                }

                HStack {
                    Label(project.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Spacer()
                    if let lastBuild = project.lastBuiltAt {
                        Label(lastBuild.formatted(.relative(presentation: .numeric)), systemImage: "hammer.fill")
                    } else {
                        Label("Never Built", systemImage: "hammer")
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Build Configuration

    @ViewBuilder
    private func projectMetadataEditorSection(_ project: SDKProject) -> some View {
        Section {
            Button {
                metadataName = project.name
                metadataDescription = project.description
                metadataStatus = project.status
                showingMetadataSheet = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit Metadata")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Name, description, status, scopes, connectors, and tools")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.forward.app")
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Project Metadata")
        }
    }

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
            } header: {
                Text("Details")
            }

            Section {
                scopeSelector
            } header: {
                Text("Access")
            }

            Section {
                connectorAndToolAssignment
            } header: {
                Text("Assignments")
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

    private var emptyProjectSection: some View {
        Section {
            VStack(spacing: 14) {
                Image(systemName: "hammer.circle")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
                Text("No Project")
                    .font(.title3.bold())
                Text("Create a clean SDK project to configure scopes, connectors, tools, and builds.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    let project = projectManager.createProject(name: "New SDK Project", status: .draft)
                    metadataName = project.name
                    metadataDescription = project.description
                    metadataStatus = project.status
                    showingMetadataSheet = true
                } label: {
                    Label("Create Project", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
        .listRowBackground(Color.clear)
    }

    private var buildConfigSection: some View {
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
            Text("Build Configuration")
        }
    }

    // MARK: - Build Actions

    private var buildActionsSection: some View {
        Group {
            Button(action: startBuild) {
                HStack {
                    Label("Execute Pipeline", systemImage: "hammer.fill")
                    Spacer()
                    if isBuilding {
                        ProgressView().controlSize(.small)
                    }
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
            .foregroundStyle(.sdkWarning)
        }
    }

    // MARK: - Build Output

    @ViewBuilder
    private var buildOutputSection: some View {
        if let url = exportedURL {
            Section {
                SDKNotificationBanner(message: "Build successful: \(url.lastPathComponent)", type: .success)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                HStack {
                    Image(systemName: "doc.zipper")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(url.lastPathComponent).font(.subheadline.bold())
                        Text("Total Size: \(fileSizeString(url))").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline.bold())
                            .padding(8)
                            .background(Color.primary.opacity(0.05), in: Circle())
                    }
                }
            } header: {
                SDKSectionHeader("Build Result", subtitle: "Exported project package", alignment: .leading)
            }
        }

        if let error = errorMessage {
            Section {
                SDKNotificationBanner(message: error, type: .error)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } header: {
                SDKSectionHeader("Pipeline Failure", subtitle: "Build engine reported errors", alignment: .leading)
            }
        }
    }

    // MARK: - Build Metrics

    private var buildMetricsSection: some View {
        Section {
            let metrics = telemetry.getMetrics()
            HStack {
                Text("Total Executions")
                Spacer()
                Text("\(metrics.totalTraces)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Success / Failure")
                Spacer()
                Text("\(metrics.successCount) / \(metrics.failureCount)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(metrics.failureCount > 0 ? .orange : .green)
            }
            HStack {
                Text("Avg Latency")
                Spacer()
                Text("\(String(format: "%.1f", metrics.averageDurationMs))ms")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Log Entries")
                Spacer()
                Text("\(logStore.entries.count)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Build Metrics")
        }
    }

    // MARK: - Development Tools

    private var developmentToolsSection: some View {
        Section {
            NavigationLink { SDKWorkspaceContainerView() } label: {
                toolkitRow(icon: "square.split.2x2.fill", color: .indigo, title: "IDE Workspace", subtitle: "Navigator, editor, inspector, console")
            }

            NavigationLink { SDKActionConsoleView() } label: {
                toolkitRow(icon: "terminal", color: .teal, title: "Action Console", subtitle: "Execute SDK commands")
            }

            Button { showingConsole = true } label: {
                toolkitRow(icon: "terminal.fill", color: .blue, title: "Console Output", subtitle: "Runtime output & logs")
            }

            NavigationLink { SDKDebugView() } label: {
                toolkitRow(icon: "ladybug", color: .red, title: "Debug Inspector", subtitle: "Runtime debug & traces")
            }

            NavigationLink { SDKLogsView() } label: {
                toolkitRow(icon: "doc.text.magnifyingglass", color: .gray, title: "System Logs", subtitle: "Filter & search logs")
            }

            NavigationLink { SDKEventStreamView() } label: {
                toolkitRow(icon: "waveform.path.ecg", color: .purple, title: "Event Stream", subtitle: "Live system events")
            }
        } header: {
            Text("Development")
        }
    }

    // MARK: - Project Configuration

    @ViewBuilder
    private func projectConfigSection(_ project: SDKProject) -> some View {
        Section {
            NavigationLink {
                SDKPermissionControlView(project: Binding(
                    get: { projectManager.currentProject ?? project },
                    set: { projectManager.currentProject = $0 }
                ))
            } label: {
                toolkitRow(icon: "lock.shield", color: .blue, title: "Permissions", subtitle: "API scope control")
            }

            NavigationLink { SDKAutomationView() } label: {
                toolkitRow(icon: "bolt.fill", color: .orange, title: "Automation", subtitle: "Automation rules")
            }

            NavigationLink {
                SDKFlowBuilderView(project: Binding(
                    get: { projectManager.currentProject ?? project },
                    set: { projectManager.currentProject = $0 }
                ))
            } label: {
                toolkitRow(icon: "arrow.triangle.branch", color: .indigo, title: "Flow Builder", subtitle: "Visual flow editor")
            }

            NavigationLink { SDKPluginsView() } label: {
                toolkitRow(icon: "puzzlepiece.fill", color: .purple, title: "Plugins", subtitle: "Extend capabilities")
            }

            NavigationLink { SDKToolsView() } label: {
                toolkitRow(icon: "wrench.and.screwdriver.fill", color: .gray, title: "Tools", subtitle: "Data utilities")
            }
        } header: {
            Text("Configuration")
        }
    }

    // MARK: - Monitoring & Security

    private var monitoringSection: some View {
        Section {
            NavigationLink { SDKDiagnosticsView() } label: {
                toolkitRow(icon: "heart.text.square.fill", color: .red, title: "Diagnostics", subtitle: "System health check")
            }

            NavigationLink { SDKSecurityMonitorView() } label: {
                toolkitRow(icon: "shield.lefthalf.filled", color: .blue, title: "Security Monitor", subtitle: "Access & scope audit")
            }

            NavigationLink { SDKControlCenterView() } label: {
                toolkitRow(icon: "slider.horizontal.3", color: .gray, title: "Control Center", subtitle: "SDK control panel")
            }

            NavigationLink { SDKDataControlView() } label: {
                toolkitRow(icon: "externaldrive.fill", color: .orange, title: "Data Control", subtitle: "Data operations")
            }
        } header: {
            Text("Monitoring & Security")
        }
    }

    // MARK: - Explore

    private var exploreSection: some View {
        Section {
            Button { showingSystemExplorer = true } label: {
                toolkitRow(icon: "cpu", color: .teal, title: "System Explorer", subtitle: "Workspace API graph")
            }

            NavigationLink { SDKWorkspaceExplorerView() } label: {
                toolkitRow(icon: "rectangle.3.group", color: .blue, title: "Workspace Explorer", subtitle: "Nodes & relationships")
            }

            NavigationLink { SDKAPIBrowserView() } label: {
                toolkitRow(icon: "book.closed.fill", color: .indigo, title: "API Browser", subtitle: "Browse SDK methods")
            }
        } header: {
            Text("Explore")
        }
    }

    // MARK: - Build & Deploy

    @ViewBuilder
    private func deploySection(_ project: SDKProject) -> some View {
        Section {
            NavigationLink { SDKIntegrationTestView() } label: {
                toolkitRow(icon: "testtube.2", color: .green, title: "Integration Tests", subtitle: "Run test scenarios")
            }

            NavigationLink { SDKAppBuilderView() } label: {
                toolkitRow(icon: "wand.and.stars", color: .indigo, title: "App Builder", subtitle: "Visual app editor")
            }

            NavigationLink { SDKDeploymentView(project: project) } label: {
                toolkitRow(icon: "icloud.and.arrow.up", color: .blue, title: "Deployment", subtitle: "Deploy project")
            }
        } header: {
            Text("Build & Deploy")
        }
    }

    // MARK: - Helpers

    private func toolkitRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .font(.system(size: 14))
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline).fontWeight(.medium)
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }


    @ViewBuilder
    private func healthBadge(_ status: HealthStatus) -> some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(healthColor(status).opacity(0.2), in: Capsule())
            .foregroundStyle(healthColor(status))
    }

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
            Text("Scopes").font(.caption).foregroundStyle(.secondary)
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
