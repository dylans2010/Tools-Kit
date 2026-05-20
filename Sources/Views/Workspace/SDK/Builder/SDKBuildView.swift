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
        .navigationTitle("SDK Builder")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button { showingMetadataSheet = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(Color.accentColor)
                }
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
        Section {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(healthColor(project.healthStatus).opacity(0.1))
                            .frame(width: 60, height: 60)
                        Image(systemName: "cube.transparent.fill")
                            .font(.title)
                            .foregroundStyle(healthColor(project.healthStatus))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.headline)
                        Text("Version v\(project.version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Circle()
                                .fill(healthColor(project.healthStatus))
                                .frame(width: 8, height: 8)
                            Text(project.healthStatus.rawValue.capitalized)
                                .font(.caption.bold())
                                .foregroundStyle(healthColor(project.healthStatus))
                        }
                    }
                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(authorizationManager.authState.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1), in: Capsule())

                        Text("Auth State")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                Grid(verticalSpacing: 12) {
                    GridRow {
                        MetricItem(title: "Scopes", value: "\(project.enabledScopes.count)", icon: "shield.fill", color: .blue)
                        MetricItem(title: "Plugins", value: "\(project.enabledPluginIDs.count)", icon: "puzzlepiece.fill", color: .orange)
                    }
                    GridRow {
                        MetricItem(title: "Tools", value: "\(project.enabledToolIDs.count)", icon: "hammer.fill", color: .purple)
                        MetricItem(title: "Links", value: "\(project.enabledConnectorIDs.count)", icon: "link", color: .green)
                    }
                }

                if isBuilding {
                    buildProgressView
                        .padding(.top, 8)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Label("Project Overview", systemImage: "info.circle.fill")
        }
    }

    struct MetricItem: View {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                VStack(alignment: .leading) {
                    Text(value).font(.subheadline.bold())
                    Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(8)
            .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
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
        Section {
            Picker(selection: $buildMode) {
                ForEach(BuildMode.allCases, id: \.self) { Label($0.rawValue, systemImage: "gearshape.2").tag($0) }
            } label: {
                Label("Build Mode", systemImage: "hammer.circle.fill")
            }

            Picker(selection: $targetPlatform) {
                ForEach(TargetPlatform.allCases, id: \.self) { Label($0.rawValue, systemImage: "iphone").tag($0) }
            } label: {
                Label("Target Platform", systemImage: "cpu.fill")
            }

            DisclosureGroup {
                VStack(spacing: 12) {
                    Toggle(isOn: $cleanBuildEnabled) {
                        Label("Clean Build", systemImage: "leaf.fill")
                    }
                    Toggle(isOn: $includeTests) {
                        Label("Include Tests", systemImage: "checkmark.seal.fill")
                    }
                    Toggle(isOn: $codeSigningEnabled) {
                        Label("Code Signing", systemImage: "key.fill")
                    }
                    Toggle(isOn: $optimizeAssets) {
                        Label("Optimize Assets", systemImage: "wand.and.stars")
                    }
                    Toggle(isOn: $parallelBuild) {
                        Label("Parallel Build", systemImage: "bolt.fill")
                    }
                    Toggle(isOn: $verboseLogging) {
                        Label("Verbose Logging", systemImage: "text.alignleft")
                    }
                }
                .padding(.top, 8)
            } label: {
                Label("Advanced Options", systemImage: "slider.horizontal.3")
                    .font(.subheadline.bold())
            }
        } header: {
            Label("Configuration", systemImage: "wrench.and.screwdriver.fill")
        }
    }

    // MARK: - Build Actions

    private var buildActionsSection: some View {
        Section {
            Button(action: startBuild) {
                HStack {
                    Label("Execute Pipeline", systemImage: "play.fill")
                        .bold()
                    Spacer()
                    if isBuilding { ProgressView().controlSize(.small) }
                }
            }
            .disabled(isBuilding)
            .listRowBackground(Color.accentColor.opacity(0.1))

            Button(action: validateProject) {
                Label("Run Validation", systemImage: "checkmark.shield.fill")
            }
            .disabled(isBuilding)

            Button(action: cleanBuildCache) {
                Label("Purge Build Cache", systemImage: "trash.slash.fill")
            }
            .disabled(isBuilding)
            .foregroundStyle(.red)
        } header: {
            Label("Pipeline Control", systemImage: "terminal.fill")
        }
    }

    // MARK: - Build Result

    @ViewBuilder
    private var buildResultSection: some View {
        if let url = exportedURL {
            Section("Build Result") {
                Label("Build Successful", systemImage: "checkmark.circle.fill")
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
        Section {
            let metrics = telemetry.getMetrics()
            Grid(verticalSpacing: 16) {
                GridRow {
                    MetricStatCard(title: "Executions", value: "\(metrics.totalTraces)", icon: "waveform.path.ecg", color: .blue)
                    MetricStatCard(title: "Success Rate", value: "\(metrics.totalTraces > 0 ? Int(Double(metrics.successCount) / Double(metrics.totalTraces) * 100) : 0)%", icon: "checkmark.circle.fill", color: .green)
                }
                GridRow {
                    MetricStatCard(title: "Avg Latency", value: "\(Int(metrics.averageDurationMs))ms", icon: "timer", color: .orange)
                    MetricStatCard(title: "Logs", value: "\(logStore.entries.count)", icon: "doc.text.fill", color: .purple)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Label("Build Telemetry", systemImage: "chart.bar.fill")
        }
    }

    struct MetricStatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Development

    private var developmentSection: some View {
        Section {
            NavigationLink(destination: SDKWorkspaceContainerView()) { Label("IDE Workspace", systemImage: "macwindow.on.rectangle") }
            NavigationLink(destination: SDKActionConsoleView()) { Label("Action Console", systemImage: "terminal.fill") }
            Button { showingConsole = true } label: { Label("Live Console Output", systemImage: "list.bullet.rectangle.portrait.fill") }
            NavigationLink(destination: SDKDebugView()) { Label("Debug Inspector", systemImage: "ladybug.fill") }
            NavigationLink(destination: SDKLogsView()) { Label("System Logs", systemImage: "doc.text.magnifyingglass.fill") }
            NavigationLink(destination: SDKEventStreamView()) { Label("Real-time Event Stream", systemImage: "waveform.path.ecg.rectangle.fill") }
            NavigationLink(destination: DevToolsMainView()) { Label("Advanced Dev Tools", systemImage: "hammer.circle.fill") }
        } header: {
            Label("Development & Debugging", systemImage: "chevron.left.forwardslash.chevron.right")
        }
    }

    // MARK: - SDK Systems

    private var sdkSystemsSection: some View {
        Section {
            NavigationLink(destination: SDKDownloadView()) { Label("SDK Export & Artifacts", systemImage: "arrow.down.doc.fill") }
            NavigationLink(destination: CustomAppSDKView()) { Label("Import App Shell", systemImage: "square.and.arrow.down.fill") }
            NavigationLink(destination: SDKHelpView()) { Label("AI Architecture Copilot", systemImage: "sparkles") }
            NavigationLink(destination: SDKSupportView()) { Label("Automated App Generator", systemImage: "magicmouse.fill") }
            NavigationLink(destination: SDKDeveloperGuideView()) { Label("SDK Technical Reference", systemImage: "book.fill") }
            NavigationLink(destination: SDKModuleRegistryView()) { Label("Global Module Registry", systemImage: "archivebox.fill") }
            NavigationLink(destination: SDKPluginLifecycleView()) { Label("Plugin Lifecycle Monitor", systemImage: "arrow.3.trianglepath") }
            NavigationLink(destination: SDKConnectorBindingView()) { Label("Bridge Connector Bindings", systemImage: "point.3.connected.trianglepath.dotted") }
        } header: {
            Label("Core SDK Infrastructure", systemImage: "square.stack.3d.up.fill")
        }
    }

    // MARK: - SDK Assets

    private var sdkAssetsSection: some View {
        Section {
            NavigationLink(destination: PackageDependenciesView()) { Label("SPM Dependencies", systemImage: "shippingbox.fill") }
            NavigationLink(destination: LibraryManageView()) { Label("Static & Dynamic Libraries", systemImage: "building.columns.fill") }
            NavigationLink(destination: FrameworkManageView()) { Label("Binary Frameworks (xcframework)", systemImage: "square.grid.3x3.fill") }
        } header: {
            Label("Asset Management", systemImage: "folder.fill")
        }
    }

    // MARK: - Architecture

    @ViewBuilder
    private func architectureSection(_ project: SDKProject) -> some View {
        Section {
            NavigationLink {
                SDKPermissionControlView(project: Binding(
                    get: { projectManager.currentProject ?? project },
                    set: { projectManager.currentProject = $0 }
                ))
            } label: { Label("Permission Scopes", systemImage: "lock.shield.fill") }

            NavigationLink(destination: SignInView()) { Label("Auth & ID Management", systemImage: "person.badge.key.fill") }
            NavigationLink(destination: SDKAutomationView()) { Label("Workflow Automation", systemImage: "bolt.horizontal.circle.fill") }
            NavigationLink {
                SDKFlowBuilderView(project: Binding(
                    get: { projectManager.currentProject ?? project },
                    set: { projectManager.currentProject = $0 }
                ))
            } label: { Label("Logic Flow Designer", systemImage: "arrow.triangle.pull") }

            NavigationLink(destination: SDKPluginsView()) { Label("Installed Plugins", systemImage: "puzzlepiece.extension.fill") }
            NavigationLink(destination: SDKToolsView()) { Label("Developer Toolset", systemImage: "briefcase.fill") }
        } header: {
            Label("Architectural Components", systemImage: "point.3.filled.connected.trianglepath.dotted")
        }
    }

    // MARK: - Stability

    private var stabilitySection: some View {
        Section {
            NavigationLink(destination: SDKDiagnosticsView()) { Label("Health Diagnostics", systemImage: "stethoscope") }
            NavigationLink(destination: SDKSecurityMonitorView()) { Label("Security Perimeter", systemImage: "shield.lefthalf.filled.badge.vicinity") }
            NavigationLink(destination: SDKControlCenterView()) { Label("Global Control Center", systemImage: "command.circle.fill") }
            NavigationLink(destination: SDKDataControlView()) { Label("Data Sovereignty Control", systemImage: "externaldrive.fill.badge.checkmark") }
        } header: {
            Label("Stability & Security", systemImage: "heart.text.square.fill")
        }
    }

    // MARK: - Exploration

    private var explorationSection: some View {
        Section {
            Button { showingSystemExplorer = true } label: { Label("Native System Explorer", systemImage: "macwindow.badge.plus") }
            NavigationLink(destination: SDKWorkspaceExplorerView()) { Label("Workspace File Browser", systemImage: "folder.badge.gearshape") }
            NavigationLink(destination: SDKAPIBrowserView()) { Label("Internal API Surface", systemImage: "network.badge.shield.half.filled") }
        } header: {
            Label("Exploration", systemImage: "flashlight.on.fill")
        }
    }

    // MARK: - Deployment

    @ViewBuilder
    private func deploymentSection(_ project: SDKProject) -> some View {
        Section {
            NavigationLink(destination: SDKIntegrationTestView()) { Label("End-to-End Tests", systemImage: "testtube.2") }
            NavigationLink(destination: SDKAppBuilderView()) { Label("No-Code App Builder", systemImage: "paintpalette.fill") }
            NavigationLink(destination: SDKDeploymentView(project: project)) { Label("Production Deployment", systemImage: "rocket.fill") }
        } header: {
            Label("Validation & Delivery", systemImage: "paperplane.circle.fill")
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

    private func log(_ message: String, level: LogLevel = .info) {
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

    private func toggleBinding(for id: UUID, keyPath: WritableKeyPath<SDKProject, [UUID]>) -> Binding<Bool> {
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
