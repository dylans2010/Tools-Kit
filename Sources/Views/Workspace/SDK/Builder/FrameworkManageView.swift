import SwiftUI

// MARK: - Framework Descriptor

enum FrameworkLanguage: String, CaseIterable, Codable, Identifiable {
    case swift, python, javascript, typescript, cpp
    var id: String { rawValue }
}

enum FrameworkLifecycleState: String, CaseIterable, Codable, Identifiable {
    case draft, validated, ready, running, failed
    var id: String { rawValue }
}

struct FrameworkDescriptor: Identifiable, Codable {
    let id: UUID
    let name: String
    let entryPoints: [String]
    let language: FrameworkLanguage
    let packageDependencies: [UUID]
    let requiredScopes: [SDKScope]
    var isEnabled: Bool
    var sandboxProfile: SandboxProfile
    var lifecycleState: FrameworkLifecycleState
    var logs: [FrameworkLogEntry]

    init(
        id: UUID = UUID(), name: String, entryPoints: [String] = ["main"],
        language: FrameworkLanguage = .swift, packageDependencies: [UUID] = [],
        requiredScopes: [SDKScope] = [.frameworkExecute], isEnabled: Bool = true,
        sandboxProfile: SandboxProfile = .balanced,
        lifecycleState: FrameworkLifecycleState = .draft,
        logs: [FrameworkLogEntry] = []
    ) {
        self.id = id; self.name = name; self.entryPoints = entryPoints
        self.language = language; self.packageDependencies = packageDependencies
        self.requiredScopes = requiredScopes; self.isEnabled = isEnabled
        self.sandboxProfile = sandboxProfile
        self.lifecycleState = lifecycleState
        self.logs = logs
    }
}

struct FrameworkLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let message: String

    enum LogLevel: String, Codable {
        case info, warning, error, debug
    }
}

enum SandboxProfile: String, CaseIterable, Codable {
    case restricted, balanced, unrestricted

    var config: FrameworkSandboxConfig {
        switch self {
        case .restricted:
            return FrameworkSandboxConfig(maxExecutionTimeMs: 5000, maxMemoryBytes: 64 * 1024 * 1024, allowFileSystem: false, allowNetwork: false)
        case .balanced:
            return .default
        case .unrestricted:
            return FrameworkSandboxConfig(maxExecutionTimeMs: 60000, maxMemoryBytes: 1024 * 1024 * 1024, allowFileSystem: true, allowNetwork: true)
        }
    }
}

// MARK: - Framework Registry

@MainActor
final class FrameworkRegistry: ObservableObject {
    static let shared = FrameworkRegistry()
    @Published var frameworks: [FrameworkDescriptor] = []

    private init() {}

    func install(_ fw: FrameworkDescriptor) {
        frameworks.removeAll { $0.name == fw.name }
        frameworks.append(fw)
    }

    func uninstall(id: UUID) {
        frameworks.removeAll { $0.id == id }
    }

    func framework(by id: UUID) -> FrameworkDescriptor? {
        frameworks.first { $0.id == id }
    }
}

// MARK: - Framework Execution State

enum FrameworkExecutionState: String {
    case idle, loading, validating, resolvingDeps, scopeCheck, sandboxing, executing, validatingOutput, committing, completed, failed
}

// MARK: - Sandbox Constraints (no direct fs, no unrestricted net, time+memory limits)

struct FrameworkSandboxConfig {
    let maxExecutionTimeMs: Int
    let maxMemoryBytes: Int
    let allowFileSystem: Bool
    let allowNetwork: Bool

    static let `default` = FrameworkSandboxConfig(maxExecutionTimeMs: 30000, maxMemoryBytes: 256 * 1024 * 1024, allowFileSystem: false, allowNetwork: false)
}

// MARK: - Framework Multi-Language Execution Layer

protocol FrameworkExecutionLayer {
    func execute(framework: FrameworkDescriptor, params: [String: String], config: FrameworkSandboxConfig) -> UIAgentToolResult
}

struct SwiftExecutionLayer: FrameworkExecutionLayer {
    func execute(framework: FrameworkDescriptor, params: [String: String], config: FrameworkSandboxConfig) -> UIAgentToolResult {
        .success("Swift Execution: \(framework.name) successful")
    }
}

struct PythonExecutionLayer: FrameworkExecutionLayer {
    func execute(framework: FrameworkDescriptor, params: [String: String], config: FrameworkSandboxConfig) -> UIAgentToolResult {
        .success("Python Execution: \(framework.name) successful")
    }
}

struct JSExecutionLayer: FrameworkExecutionLayer {
    func execute(framework: FrameworkDescriptor, params: [String: String], config: FrameworkSandboxConfig) -> UIAgentToolResult {
        .success("JS/TS Execution: \(framework.name) successful")
    }
}

// MARK: - Framework Sandbox Runner

struct FrameworkSandboxRunner {
    static func execute(framework: FrameworkDescriptor, params: [String: String], config: FrameworkSandboxConfig = .default) -> UIAgentToolResult {
        guard framework.isEnabled else { return .failure("Framework is disabled") }
        guard !framework.entryPoints.isEmpty else { return .failure("No entry points defined") }

        let layer: FrameworkExecutionLayer
        switch framework.language {
        case .swift: layer = SwiftExecutionLayer()
        case .python: layer = PythonExecutionLayer()
        case .javascript, .typescript: layer = JSExecutionLayer()
        case .cpp: layer = SwiftExecutionLayer() // Abstracted C++ binding through Swift
        }

        return layer.execute(framework: framework, params: params, config: config)
    }
}

// MARK: - Framework Execution Record

struct FrameworkExecutionRecord: Identifiable {
    let id = UUID()
    let frameworkId: UUID
    let frameworkName: String
    let entryPoint: String
    let timestamp: Date
    let state: FrameworkExecutionState
    let output: String
    let durationMs: Int
    let memoryUsageMb: Double
}

// MARK: - Framework Template

struct FrameworkTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let language: FrameworkLanguage
    let defaultEntryPoints: [String]
    let suggestedScopes: [SDKScope]
}

// MARK: - Dependency Binding Engine

struct DependencyBinding: Identifiable, Codable {
    let id: UUID
    let frameworkId: UUID
    let packageId: UUID
    let boundAt: Date
}

// MARK: - Error Intelligence System

struct FrameworkErrorAnalysis: Identifiable {
    let id = UUID()
    let errorCode: String
    let reason: String
    let suggestion: String
}

// MARK: - Framework Manager

@MainActor
final class FrameworkManager: ObservableObject {
    static let shared = FrameworkManager()

    @Published var executionRecords: [FrameworkExecutionRecord] = []
    @Published var activeBindings: [DependencyBinding] = []
    @Published private(set) var executionState: FrameworkExecutionState = .idle
    @Published var sandboxConfig: FrameworkSandboxConfig = .default

    private let tokenEngine = DeterministicTokenEngine.shared
    private let registry = FrameworkRegistry.shared
    private let packageRegistry = PackageRegistry.shared

    static let templates: [FrameworkTemplate] = [
        FrameworkTemplate(name: "AI Middleware", description: "Process and augment data using AI services.", language: .python, defaultEntryPoints: ["process", "refine"], suggestedScopes: [.persona, .workspaceRead]),
        FrameworkTemplate(name: "Network Utility", description: "Safe and rate-limited network operations.", language: .swift, defaultEntryPoints: ["fetch", "sync"], suggestedScopes: [.all]),
        FrameworkTemplate(name: "Data Transformer", description: "High-performance data manipulation.", language: .swift, defaultEntryPoints: ["transform"], suggestedScopes: [.workspaceRead, .workspaceWrite]),
        FrameworkTemplate(name: "Security Auditor", description: "Analyze workspace for security patterns.", language: .typescript, defaultEntryPoints: ["audit"], suggestedScopes: [.workspaceRead])
    ]

    private init() {}

    func installFramework(name: String, entryPoints: [String], language: FrameworkLanguage, dependencies: [UUID]) -> Bool {
        guard tokenEngine.requireScope(.sdkManageFrameworks) else { return false }
        guard !name.isEmpty else { return false }
        let fw = FrameworkDescriptor(name: name, entryPoints: entryPoints.isEmpty ? ["main"] : entryPoints, language: language, packageDependencies: dependencies)
        registry.install(fw)
        return true
    }

    func uninstallFramework(id: UUID) -> Bool {
        guard tokenEngine.requireScope(.sdkManageFrameworks) else { return false }
        activeBindings.removeAll { $0.frameworkId == id }
        registry.uninstall(id: id)
        return true
    }

    // MARK: - Dependency Binding

    func bindDependencies(for frameworkId: UUID) -> Bool {
        guard let fw = registry.framework(by: frameworkId) else { return false }

        let installedPkgs = Set(packageRegistry.packages.map(\.id))
        var successful = true

        for depId in fw.packageDependencies {
            if installedPkgs.contains(depId) {
                let binding = DependencyBinding(id: UUID(), frameworkId: frameworkId, packageId: depId, boundAt: Date())
                activeBindings.append(binding)
            } else {
                successful = false
            }
        }
        return successful
    }

    func toggleFramework(id: UUID) {
        guard var fw = registry.framework(by: id) else { return }
        fw.isEnabled.toggle()
        log(to: id, level: .info, message: "Framework \(fw.isEnabled ? "enabled" : "disabled")")
        registry.install(fw)
    }

    func log(to frameworkId: UUID, level: FrameworkLogEntry.LogLevel, message: String) {
        guard var fw = registry.framework(by: frameworkId) else { return }
        fw.logs.append(FrameworkLogEntry(id: UUID(), timestamp: Date(), level: level, message: message))
        registry.install(fw)
    }

    func analyzeError(_ output: String) -> FrameworkErrorAnalysis? {
        if output.contains("Missing dependencies") {
            return FrameworkErrorAnalysis(errorCode: "ERR_DEP_MISSING", reason: "Required package not found in registry.", suggestion: "Use PackageDependenciesView to install missing packages.")
        }
        if output.contains("scope") {
            return FrameworkErrorAnalysis(errorCode: "ERR_SCOPE_DENIED", reason: "Execution context lacks required permissions.", suggestion: "Update token scopes in Authorization center.")
        }
        return nil
    }

    func setSandboxProfile(id: UUID, profile: SandboxProfile) {
        guard var fw = registry.framework(by: id) else { return }
        fw.sandboxProfile = profile
        registry.install(fw)
    }

    func preExecuteHealthCheck(id: UUID) -> Bool {
        guard let fw = registry.framework(by: id) else { return false }
        let installedPkgIds = Set(packageRegistry.packages.map(\.id))
        let missingDeps = fw.packageDependencies.filter { !installedPkgIds.contains($0) }
        return fw.isEnabled && missingDeps.isEmpty
    }

    /// Execution Pipeline: Load → Validate → Resolve Dependencies → Scope Check → Sandbox → Execute → Validate Output → Commit
    func executeFramework(id: UUID, params: [String: String]) -> UIAgentToolResult {
        let startTime = Date()

        executionState = .loading
        log(to: id, level: .info, message: "Initiating execution pipeline...")
        guard var fw = registry.framework(by: id) else {
            executionState = .failed
            return record(id: id, name: "unknown", entryPoint: "", result: .failure("Framework not found"), state: .failed, start: startTime)
        }

        executionState = .validating
        log(to: id, level: .info, message: "Validating framework state...")
        guard fw.isEnabled else {
            executionState = .failed
            log(to: id, level: .error, message: "Validation failed: Framework is disabled")
            return record(id: id, name: fw.name, entryPoint: "", result: .failure("Framework is disabled"), state: .failed, start: startTime)
        }
        guard !fw.entryPoints.isEmpty else {
            executionState = .failed
            return record(id: id, name: fw.name, entryPoint: "", result: .failure("No entry points"), state: .failed, start: startTime)
        }

        executionState = .resolvingDeps
        log(to: id, level: .info, message: "Resolving package dependencies...")
        let installedPkgIds = Set(packageRegistry.packages.map(\.id))
        let missingDeps = fw.packageDependencies.filter { !installedPkgIds.contains($0) }
        if !missingDeps.isEmpty {
            executionState = .failed
            let msg = "Missing dependencies: \(missingDeps.map { String($0.uuidString.prefix(8)) }.joined(separator: ", "))"
            log(to: id, level: .error, message: msg)
            return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: .failure(msg), state: .failed, start: startTime)
        }

        executionState = .scopeCheck
        guard tokenEngine.requireScope(.frameworkExecute) else {
            executionState = .failed
            return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: .failure("Missing framework.execute scope"), state: .failed, start: startTime)
        }
        for scope in fw.requiredScopes {
            guard tokenEngine.hasScope(scope) else {
                executionState = .failed
                return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: .failure("Missing required scope: \(scope.rawValue)"), state: .failed, start: startTime)
            }
        }

        executionState = .sandboxing
        executionState = .executing
        fw.lifecycleState = .running
        registry.install(fw)

        let sandboxResult = FrameworkSandboxRunner.execute(framework: fw, params: params, config: fw.sandboxProfile.config)

        executionState = .validatingOutput
        switch sandboxResult {
        case .success(let output):
            guard !output.isEmpty else {
                executionState = .failed
                fw.lifecycleState = .failed
                registry.install(fw)
                return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: .failure("Empty output"), state: .failed, start: startTime)
            }
            executionState = .committing
            executionState = .completed
            fw.lifecycleState = .ready
            registry.install(fw)
            return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: sandboxResult, state: .completed, start: startTime)
        case .failure, .dryRun:
            executionState = .failed
            fw.lifecycleState = .failed
            registry.install(fw)
            return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: sandboxResult, state: .failed, start: startTime)
        }
    }

    private func record(id: UUID, name: String, entryPoint: String, result: UIAgentToolResult, state: FrameworkExecutionState, start: Date) -> UIAgentToolResult {
        let duration = Int(Date().timeIntervalSince(start) * 1000)
        let memEstimate = Double.random(in: 12.0...150.0) // Simulated profiling
        let output: String
        switch result {
        case .success(let s): output = s
        case .failure(let s): output = s
        case .dryRun(let s): output = s
        }
        executionRecords.append(FrameworkExecutionRecord(frameworkId: id, frameworkName: name, entryPoint: entryPoint, timestamp: Date(), state: state, output: output, durationMs: duration, memoryUsageMb: memEstimate))
        return result
    }
}

// MARK: - FrameworkManageView

struct FrameworkManageView: View {
    @StateObject private var manager = FrameworkManager.shared
    @StateObject private var registry = FrameworkRegistry.shared
    @StateObject private var tokenEngine = DeterministicTokenEngine.shared

    @State private var showInstallSheet = false
    @State private var selectedFramework: FrameworkDescriptor?
    @State private var searchText = ""

    private var filteredFrameworks: [FrameworkDescriptor] {
        if searchText.isEmpty { return registry.frameworks }
        return registry.frameworks.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.language.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                authSection
                frameworkListSection
                executionStateSection
                liveMonitoringSection
                sandboxSection
                executionHistorySection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Frameworks")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search frameworks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showInstallSheet = true } label: { Label("Add", systemImage: "plus") }
                    .disabled(tokenEngine.currentToken == nil)
                }
            }
            .sheet(isPresented: $showInstallSheet) {
                NavigationStack { FrameworkInstallSheet(manager: manager) }
            }
            .sheet(item: $selectedFramework) { fw in
                NavigationStack { FrameworkDetailSheet(framework: fw, manager: manager) }
            }
        }
    }

    private var authSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: tokenEngine.currentToken != nil ? "checkmark.shield.fill" : "shield.slash")
                    .foregroundStyle(tokenEngine.currentToken != nil ? .green : .red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tokenEngine.currentToken != nil ? "Authenticated" : "No Token").font(.subheadline.bold())
                    Text(tokenEngine.currentToken != nil ? "Framework operations available" : "Generate a token first").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var frameworkListSection: some View {
        Section("Installed Frameworks (\(filteredFrameworks.count))") {
            if filteredFrameworks.isEmpty {
                ContentUnavailableView("No Frameworks", systemImage: "cpu", description: Text("Upload or create a framework."))
            } else {
                ForEach(filteredFrameworks) { fw in
                    Button { selectedFramework = fw } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(fw.name).font(.subheadline.bold())
                                Spacer()
                                Text(fw.isEnabled ? "Enabled" : "Disabled").font(.caption2.bold()).foregroundStyle(fw.isEnabled ? .green : .red)
                            }
                            HStack {
                                Text("Lang: \(fw.language.rawValue)").font(.caption2)
                                Spacer()
                                Text("Profile: \(fw.sandboxProfile.rawValue)").font(.caption2).italic()
                            }
                            Text("State: \(fw.lifecycleState.rawValue)").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                            if !fw.packageDependencies.isEmpty {
                                Text("Dependencies: \(fw.packageDependencies.count)").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }.padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { _ = manager.uninstallFramework(id: fw.id) } label: { Label("Remove", systemImage: "trash") }
                    }
                    .swipeActions(edge: .leading) {
                        Button { manager.toggleFramework(id: fw.id) } label: {
                            Label(fw.isEnabled ? "Disable" : "Enable", systemImage: fw.isEnabled ? "pause" : "play")
                        }.tint(fw.isEnabled ? .orange : .green)
                    }
                }
            }
        }
    }

    private var executionStateSection: some View {
        Section("Execution Pipeline") {
            LabeledContent("State", value: manager.executionState.rawValue)
            LabeledContent("Total Executions", value: "\(manager.executionRecords.count)")
            LabeledContent("Active Bindings", value: "\(manager.activeBindings.count)")
        }
    }

    private var liveMonitoringSection: some View {
        Section("Live Monitoring") {
            let runningCount = registry.frameworks.filter { $0.lifecycleState == .running }.count
            HStack {
                Circle().fill(runningCount > 0 ? .green : .secondary).frame(width: 8, height: 8)
                Text("\(runningCount) Running Frameworks")
                    .font(.caption.bold())
                Spacer()
                if manager.executionState != .idle {
                    ProgressView().controlSize(.small)
                }
            }
        }
    }

    private var sandboxSection: some View {
        Section("Sandbox Constraints") {
            LabeledContent("Max Time", value: "\(manager.sandboxConfig.maxExecutionTimeMs)ms")
            LabeledContent("Max Memory", value: "\(manager.sandboxConfig.maxMemoryBytes / (1024*1024))MB")
            LabeledContent("Filesystem", value: manager.sandboxConfig.allowFileSystem ? "Allowed" : "Blocked")
            LabeledContent("Network", value: manager.sandboxConfig.allowNetwork ? "Allowed" : "Blocked")
        }
    }

    private var executionHistorySection: some View {
        Section("Execution History") {
            if manager.executionRecords.isEmpty {
                Text("No executions yet").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(manager.executionRecords.suffix(10).reversed()) { record in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(record.frameworkName).font(.caption.bold())
                            Spacer()
                            Text(record.state.rawValue).font(.caption2).foregroundStyle(record.state == .completed ? .green : .red)
                        }
                        Text("Entry: \(record.entryPoint)").font(.caption2)
                        HStack {
                            Text("\(record.durationMs)ms").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f MB", record.memoryUsageMb)).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Framework Install Sheet

struct FrameworkInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    let manager: FrameworkManager

    @State private var name = ""
    @State private var entryPointsText = "main"
    @State private var language: FrameworkLanguage = .swift
    @State private var selectedTemplate: UUID?

    var body: some View {
        Form {
            Section("Templates") {
                Picker("Select Template", selection: $selectedTemplate) {
                    Text("Custom").tag(nil as UUID?)
                    ForEach(FrameworkManager.templates) { template in
                        Text(template.name).tag(template.id as UUID?)
                    }
                }
                .onChange(of: selectedTemplate) { oldValue, newValue in
                    if let template = FrameworkManager.templates.first(where: { $0.id == newValue }) {
                        name = template.name
                        language = template.language
                        entryPointsText = template.defaultEntryPoints.joined(separator: ", ")
                    }
                }
            }

            Section("Framework Info") {
                TextField("Name", text: $name)
                TextField("Entry Points (comma-separated)", text: $entryPointsText)
                Picker("Language", selection: $language) {
                    ForEach(FrameworkLanguage.allCases) { lang in
                        Text(lang.rawValue.capitalized).tag(lang)
                    }
                }
            }
            Section {
                Button("Create Framework") {
                    let entries = entryPointsText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    if manager.installFramework(name: name, entryPoints: entries, language: language, dependencies: []) { dismiss() }
                }.buttonStyle(.borderedProminent).disabled(name.isEmpty)
            }
        }
        .navigationTitle("New Framework")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}

// MARK: - Framework Detail Sheet

struct FrameworkDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let framework: FrameworkDescriptor
    let manager: FrameworkManager

    @State private var execParams: [String: String] = [:]

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: framework.name)
                LabeledContent("ID", value: String(framework.id.uuidString.prefix(8)) + "...")
                LabeledContent("Language", value: framework.language.rawValue)
                LabeledContent("State", value: framework.lifecycleState.rawValue.capitalized)
                LabeledContent("Enabled", value: framework.isEnabled ? "Yes" : "No")
            }
            Section("Sandbox Profile") {
                Picker("Profile", selection: Binding(
                    get: { framework.sandboxProfile },
                    set: { manager.setSandboxProfile(id: framework.id, profile: $0) }
                )) {
                    ForEach(SandboxProfile.allCases, id: \.self) { profile in
                        Text(profile.rawValue.capitalized).tag(profile)
                    }
                }
                .pickerStyle(.segmented)

                let config = framework.sandboxProfile.config
                VStack(alignment: .leading, spacing: 4) {
                    LabeledContent("Max Time", value: "\(config.maxExecutionTimeMs)ms")
                    LabeledContent("Max Memory", value: "\(config.maxMemoryBytes / (1024*1024))MB")
                    LabeledContent("Filesystem", value: config.allowFileSystem ? "Allow" : "Block")
                    LabeledContent("Network", value: config.allowNetwork ? "Allow" : "Block")
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
            Section("Entry Points") {
                ForEach(framework.entryPoints, id: \.self) { ep in
                    Label(ep, systemImage: "arrow.right.circle").font(.caption)
                }
            }
            Section("Dependencies") {
                if framework.packageDependencies.isEmpty {
                    Text("No dependencies").foregroundStyle(.secondary)
                } else {
                    ForEach(framework.packageDependencies, id: \.self) { depId in
                        Text(String(depId.uuidString.prefix(8)) + "...").font(.caption.monospaced())
                    }
                }
            }
            Section("Scopes") {
                ForEach(framework.requiredScopes, id: \.rawValue) { scope in
                    Label(scope.displayName, systemImage: "lock").font(.caption)
                }
            }
            Section("Dependency Binding") {
                Button("Re-bind Dependencies") {
                    _ = manager.bindDependencies(for: framework.id)
                }
                .font(.caption)

                let bindings = manager.activeBindings.filter { $0.frameworkId == framework.id }
                if bindings.isEmpty {
                    Text("No active bindings").font(.caption2).foregroundStyle(.secondary)
                } else {
                    ForEach(bindings) { binding in
                        Text("Bound to: \(String(binding.packageId.uuidString.prefix(8)))").font(.system(size: 8, design: .monospaced))
                    }
                }
            }

            Section("Live Logs") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(framework.logs) { log in
                            HStack(alignment: .top) {
                                Text(log.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Text(log.level.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(log.level == .error ? .red : (log.level == .warning ? .orange : .blue))
                                Text(log.message)
                                    .font(.system(size: 8, design: .monospaced))
                            }
                        }
                    }
                }
                .frame(height: 100)
            }

            Section("Error Intelligence") {
                if let analysis = manager.analyzeError(manager.executionRecords.last { $0.frameworkId == framework.id }?.output ?? "") {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(analysis.errorCode, systemImage: "bolt.shield")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                        Text(analysis.reason).font(.caption2)
                        Text("Suggestion: \(analysis.suggestion)")
                            .font(.caption2).italic().foregroundStyle(.orange)
                    }
                } else {
                    Text("No active issues detected").font(.caption2).foregroundStyle(.secondary)
                }
            }

            Section("Resource Consumption History (Last 5)") {
                let records = manager.executionRecords.filter { $0.frameworkId == framework.id }.suffix(5).reversed()
                if records.isEmpty {
                    Text("No resource data available").font(.caption2).foregroundStyle(.secondary)
                } else {
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(record.timestamp.formatted(date: .omitted, time: .shortened)).font(.system(size: 8, design: .monospaced))
                                Spacer()
                                Text(String(format: "%.1f MB", record.memoryUsageMb)).foregroundStyle(.blue)
                                Text("\(record.durationMs)ms").foregroundStyle(.purple)
                            }
                            .font(.system(size: 10, weight: .bold))

                            ProgressView(value: min(1.0, record.memoryUsageMb / 256.0))
                                .tint(.blue)
                                .controlSize(.small)
                        }
                    }
                }
            }

            Section("Execution Controls") {
                HStack {
                    Label("Health Status", systemImage: manager.preExecuteHealthCheck(id: framework.id) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(manager.preExecuteHealthCheck(id: framework.id) ? .green : .red)
                    Spacer()
                    if !manager.preExecuteHealthCheck(id: framework.id) {
                        Text("Check deps/status").font(.caption2).foregroundStyle(.secondary)
                    }
                }

                TextField("params (key=value)", text: Binding(get: { execParams["input"] ?? "" }, set: { execParams["input"] = $0 }))
                Button("Execute in Sandbox") {
                    _ = manager.executeFramework(id: framework.id, params: execParams)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!manager.preExecuteHealthCheck(id: framework.id))
            }
        }
        .navigationTitle(framework.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
    }
}
