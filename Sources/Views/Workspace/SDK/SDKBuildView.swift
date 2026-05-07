import SwiftUI

struct SDKBuildView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
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
        case multiPlatform = "Multi-Platform"
    }

    var body: some View {
        List {
            if let project = projectManager.currentProject {
                projectOverviewSection(project)
                buildConfigSection
                buildActionsSection
                buildOutputSection
                buildMetricsSection
                developmentToolsSection
                projectConfigSection(project)
                monitoringSection
                exploreSection
                deploySection(project)
            } else {
                Section {
                    ContentUnavailableView(
                        "No Project",
                        systemImage: "hammer.fill",
                        description: Text("Open or create a project to start building.")
                    )
                }
            }
        }
        .navigationTitle("Build")
        .sheet(isPresented: $showingConsole) {
            NavigationStack { SDKConsoleView() }
        }
        .sheet(isPresented: $showingSystemExplorer) {
            NavigationStack { SDKSystemExplorerView() }
        }
    }

    // MARK: - Project Overview

    @ViewBuilder
    private func projectOverviewSection(_ project: SDKProject) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(project.name).font(.title3).bold()
                    Spacer()
                    healthBadge(project.healthStatus)
                }

                HStack(spacing: 0) {
                    statPill(label: "\(project.enabledScopes.count)", caption: "Scopes")
                    statPill(label: "\(project.enabledPluginIDs.count)", caption: "Plugins")
                    statPill(label: "\(project.enabledToolIDs.count)", caption: "Tools")
                    statPill(label: "\(project.enabledConnectorIDs.count)", caption: "Connectors")
                    statPill(label: "\(project.automationRules.count)", caption: "Rules")
                }

                HStack {
                    Label(
                        "Created \(project.createdAt.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "calendar"
                    )
                    Spacer()
                    if let lastBuild = project.lastBuiltAt {
                        Label(lastBuild.formatted(.relative(presentation: .numeric)), systemImage: "hammer.fill")
                    } else {
                        Label("Never built", systemImage: "hammer")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Build Configuration

    private var buildConfigSection: some View {
        Section("Build Configuration") {
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
        }
    }

    // MARK: - Build Actions

    private var buildActionsSection: some View {
        Section("Actions") {
            Button(action: startBuild) {
                if isBuilding {
                    HStack {
                        Text("Building...")
                        Spacer()
                        ProgressView(value: buildProgress)
                            .frame(width: 100)
                    }
                } else {
                    Label("Build & Export", systemImage: "hammer.fill")
                }
            }
            .disabled(isBuilding)

            Button(action: quickBuild) {
                Label("Quick Build", systemImage: "hare.fill")
            }
            .disabled(isBuilding)

            Button(action: validateProject) {
                Label("Validate Project", systemImage: "checkmark.seal")
            }
            .disabled(isBuilding)

            Button(action: cleanBuildCache) {
                Label("Clean Build Cache", systemImage: "trash")
            }
            .disabled(isBuilding)
            .foregroundStyle(.orange)
        }
    }

    // MARK: - Build Output

    @ViewBuilder
    private var buildOutputSection: some View {
        if let url = exportedURL {
            Section("Build Output") {
                HStack {
                    Image(systemName: "doc.zipper")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(url.lastPathComponent).font(.headline)
                        Text("Size: \(fileSizeString(url))").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    ShareLink(item: url)
                }
            }
        }

        if let error = errorMessage {
            Section("Build Errors") {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Build Metrics

    private var buildMetricsSection: some View {
        Section("Build Metrics") {
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
        }
    }

    // MARK: - Development Tools

    private var developmentToolsSection: some View {
        Section("Development") {
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
        }
    }

    // MARK: - Project Configuration

    @ViewBuilder
    private func projectConfigSection(_ project: SDKProject) -> some View {
        Section("Configuration") {
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
        }
    }

    // MARK: - Monitoring & Security

    private var monitoringSection: some View {
        Section("Monitoring & Security") {
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
        }
    }

    // MARK: - Explore

    private var exploreSection: some View {
        Section("Explore") {
            Button { showingSystemExplorer = true } label: {
                toolkitRow(icon: "cpu", color: .teal, title: "System Explorer", subtitle: "Workspace API graph")
            }

            NavigationLink { SDKWorkspaceExplorerView() } label: {
                toolkitRow(icon: "rectangle.3.group", color: .blue, title: "Workspace Explorer", subtitle: "Nodes & relationships")
            }

            NavigationLink { SDKAPIBrowserView() } label: {
                toolkitRow(icon: "book.closed.fill", color: .indigo, title: "API Browser", subtitle: "Browse SDK methods")
            }
        }
    }

    // MARK: - Build & Deploy

    @ViewBuilder
    private func deploySection(_ project: SDKProject) -> some View {
        Section("Build & Deploy") {
            NavigationLink { SDKIntegrationTestView() } label: {
                toolkitRow(icon: "testtube.2", color: .green, title: "Integration Tests", subtitle: "Run test scenarios")
            }

            NavigationLink { SDKAppBuilderView() } label: {
                toolkitRow(icon: "wand.and.stars", color: .indigo, title: "App Builder", subtitle: "Visual app editor")
            }

            NavigationLink { SDKDeploymentView(project: project) } label: {
                toolkitRow(icon: "icloud.and.arrow.up", color: .blue, title: "Deployment", subtitle: "Deploy project")
            }
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

    private func statPill(label: String, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(.headline, design: .rounded)).bold()
            Text(caption).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
                "Build started: \(buildMode.rawValue) | \(targetPlatform.rawValue)",
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
                            "Running pre-build validation...",
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
                            "Build completed: \(url.lastPathComponent)",
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
                            "Build failed: \(error.localizedDescription)",
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

        SDKLogStore.shared.log("Quick build started", source: "SDKBuildView", level: .info)

        Task {
            await MainActor.run { buildProgress = 0.5 }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                buildProgress = 1.0
                isBuilding = false
                projectManager.currentProject?.lastBuiltAt = Date()
                try? projectManager.save()
                SDKLogStore.shared.log("Quick build completed", source: "SDKBuildView", level: .info)
            }
        }
    }

    private func validateProject() {
        guard let project = projectManager.currentProject else { return }

        var issues: [String] = []
        if project.enabledScopes.isEmpty { issues.append("No scopes enabled") }
        if project.enabledPluginIDs.isEmpty { issues.append("No plugins selected") }
        if project.enabledToolIDs.isEmpty { issues.append("No tools selected") }

        if issues.isEmpty {
            SDKLogStore.shared.log("Project validation passed", source: "SDKBuildView", level: .info)
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
}
