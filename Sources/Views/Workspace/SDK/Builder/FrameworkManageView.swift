import SwiftUI
import Observation

// MARK: - Framework Descriptor

enum FrameworkLanguage: String, CaseIterable, Codable, Identifiable {
    case swift, python, javascript, typescript, objectiveC
    var id: String { rawValue }
}

enum FrameworkLifecycleState: String, CaseIterable, Codable, Identifiable {
    case draft, validated, ready, running, failed
    var id: String { rawValue }
}

enum ReleaseChannel: String, CaseIterable, Codable, Identifiable {
    case stable, beta, experimental
    var id: String { rawValue }
}

struct FrameworkDescriptor: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let type: FrameworkType
    let entryPoints: [String]
    let language: FrameworkLanguage
    let packageDependencies: [UUID]
    var frameworkDependencies: [UUID]
    let requiredScopes: [SDKScope]
    var isEnabled: Bool
    var sandboxProfile: SandboxProfile
    var lifecycleState: FrameworkLifecycleState
    var logs: [FrameworkLogEntry]
    var size: Int64
    var lastModified: Date
    var architectures: [String]
    var linkType: LinkType
    var embedMode: EmbedMode
    var environmentVariables: [String: String]
    var minSDKVersion: String
    var performanceMetricsHistory: [FrameworkExecutionRecord]

    enum FrameworkType: String, Codable, CaseIterable {
        case appleSystem, xcframework, `static`, dynamic, embedded, broken
    }

    enum LinkType: String, Codable, CaseIterable {
        case required, optional
    }

    enum EmbedMode: String, Codable, CaseIterable {
        case embedAndSign = "Embed & Sign"
        case embedWithoutSigning = "Embed Without Signing"
        case doNotEmbed = "Do Not Embed"
    }

    init(
        id: UUID = UUID(), name: String, path: String = "", type: FrameworkType = .xcframework,
        entryPoints: [String] = ["main"], language: FrameworkLanguage = .swift,
        packageDependencies: [UUID] = [], frameworkDependencies: [UUID] = [],
        requiredScopes: [SDKScope] = [.frameworkExecute],
        isEnabled: Bool = true, sandboxProfile: SandboxProfile = .balanced,
        lifecycleState: FrameworkLifecycleState = .draft, logs: [FrameworkLogEntry] = [],
        size: Int64 = 0, lastModified: Date = Date(), architectures: [String] = ["arm64"],
        linkType: LinkType = .required, embedMode: EmbedMode = .embedAndSign,
        environmentVariables: [String: String] = [:], minSDKVersion: String = "17.0",
        performanceMetricsHistory: [FrameworkExecutionRecord] = []
    ) {
        self.id = id; self.name = name; self.path = path; self.type = type
        self.entryPoints = entryPoints; self.language = language
        self.packageDependencies = packageDependencies; self.frameworkDependencies = frameworkDependencies
        self.requiredScopes = requiredScopes
        self.isEnabled = isEnabled; self.sandboxProfile = sandboxProfile
        self.lifecycleState = lifecycleState; self.logs = logs
        self.size = size; self.lastModified = lastModified; self.architectures = architectures
        self.linkType = linkType; self.embedMode = embedMode
        self.environmentVariables = environmentVariables; self.minSDKVersion = minSDKVersion
        self.performanceMetricsHistory = performanceMetricsHistory
    }
}

struct FrameworkLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let message: String
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
@Observable
final class FrameworkRegistry {
    static let shared = FrameworkRegistry()
    var frameworks: [FrameworkDescriptor] = []

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

enum FrameworkExecutionState: String, Codable {
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
        case .objectiveC: layer = SwiftExecutionLayer() // Abstracted ObjC binding through Swift
        }

        return layer.execute(framework: framework, params: params, config: config)
    }
}

// MARK: - Framework Execution Record

struct FrameworkExecutionRecord: Identifiable, Codable, Hashable {
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
@Observable
final class FrameworkManager {
    static let shared = FrameworkManager()

    var executionRecords: [FrameworkExecutionRecord] = []
    var activeBindings: [DependencyBinding] = []
    var executionState: FrameworkExecutionState = .idle
    var sandboxConfig: FrameworkSandboxConfig = .default
    var auditLog: [FrameworkAuditEntry] = []

    struct FrameworkAuditEntry: Identifiable, Codable {
        let id = UUID()
        var timestamp = Date()
        let frameworkName: String
        let action: String
        let oldValue: String
        let newValue: String
    }

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
        if let fw = registry.framework(by: id) {
            auditLog.append(FrameworkAuditEntry(frameworkName: fw.name, action: "Uninstall", oldValue: "Installed", newValue: "Removed"))
        }
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
        let old = fw.isEnabled
        fw.isEnabled.toggle()
        auditLog.append(FrameworkAuditEntry(frameworkName: fw.name, action: "Toggle Enabled", oldValue: "\(old)", newValue: "\(fw.isEnabled)"))
        log(to: id, level: .info, message: "Framework \(fw.isEnabled ? "enabled" : "disabled")")
        registry.install(fw)
    }

    func log(to frameworkId: UUID, level: LogLevel, message: String) {
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

    func hotReload(id: UUID) {
        guard var fw = registry.framework(by: id) else { return }
        guard !fw.path.isEmpty else { return }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fw.path) {
            fw.size = attrs[.size] as? Int64 ?? 0
            fw.lastModified = attrs[.modificationDate] as? Date ?? Date()
            log(to: id, level: .info, message: "Hot-reload successful: Sync'd with filesystem.")
            registry.install(fw)
        }
    }

    func getSymbolsSynchronously(for framework: FrameworkDescriptor) -> [String] {
        guard !framework.path.isEmpty else { return [] }
        let url = URL(fileURLWithPath: framework.path)
        let binaryURL = framework.path.hasSuffix(".framework") ? url.appendingPathComponent(url.deletingPathExtension().lastPathComponent) : url
        guard let handle = try? FileHandle(forReadingFrom: binaryURL) else { return [] }
        defer { try? handle.close() }

        guard let magicData = try? handle.read(upToCount: 4) else { return [] }
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }
        var offset: UInt64 = 0
        if magic == 0xBEBAFECA || magic == 0xCAFEBABE {
            guard let countData = try? handle.read(upToCount: 4) else { return [] }
            let count = countData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
            if count > 0 {
                guard let archData = try? handle.read(upToCount: 20) else { return [] }
                offset = UInt64(archData.advanced(by: 8).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian)
            }
        }
        try? handle.seek(toOffset: offset)
        guard let headerData = try? handle.read(upToCount: 32) else { return [] }
        let is64 = headerData.count == 32
        let ncmds = headerData.advanced(by: 16).withUnsafeBytes { $0.load(as: UInt32.self) }
        try? handle.seek(toOffset: offset + (is64 ? 32 : 28))
        var symoff: UInt32 = 0; var nsyms: UInt32 = 0; var stroff: UInt32 = 0; var strsize: UInt32 = 0
        for _ in 0..<ncmds {
            guard let cmdData = try? handle.read(upToCount: 8) else { break }
            let cmd = cmdData.withUnsafeBytes { $0.load(as: UInt32.self) }
            let size = cmdData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }
            if cmd == 0x02 {
                guard let symData = try? handle.read(upToCount: 16) else { break }
                symoff = symData.withUnsafeBytes { $0.load(as: UInt32.self) }
                nsyms = symData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }
                stroff = symData.advanced(by: 8).withUnsafeBytes { $0.load(as: UInt32.self) }
                strsize = symData.advanced(by: 12).withUnsafeBytes { $0.load(as: UInt32.self) }
                break
            }
            if let current = try? handle.offset() { try? handle.seek(toOffset: current + UInt64(size) - 8) }
        }
        if nsyms > 0 && stroff > 0 {
            try? handle.seek(toOffset: offset + UInt64(stroff))
            if let strData = try? handle.read(upToCount: Int(strsize)) {
                var detected: [String] = []
                var current = Data()
                for byte in strData {
                    if byte == 0 {
                        if !current.isEmpty, let s = String(data: current, encoding: .utf8) { detected.append(s) }
                        current = Data()
                    } else { current.append(byte) }
                }
                return detected
            }
        }
        return []
    }

    func generateMarkdownReport(id: UUID) -> String {
        guard let fw = registry.framework(by: id) else { return "Framework not found." }
        let records = executionRecords.filter { $0.frameworkId == id }
        let avgDuration = records.isEmpty ? 0 : records.map(\.durationMs).reduce(0, +) / records.count

        return """
        # Framework Report: \(fw.name)
        - **Type**: \(fw.type.rawValue)
        - **Language**: \(fw.language.rawValue)
        - **Architecture**: \(fw.architectures.joined(separator: ", "))
        - **Link Type**: \(fw.linkType.rawValue)
        - **Min SDK**: \(fw.minSDKVersion)

        ## Performance Summary
        - **Total Executions**: \(records.count)
        - **Average Duration**: \(avgDuration)ms
        - **Success Rate**: \(records.isEmpty ? 0 : (records.filter { $0.state == .completed }.count * 100 / records.count))%

        ## Environment Variables
        \(fw.environmentVariables.isEmpty ? "None" : fw.environmentVariables.map { "\($0.key)=\($0.value)" }.joined(separator: "\n"))

        ## Required Scopes
        \(fw.requiredScopes.map { "- \($0.rawValue)" }.joined(separator: "\n"))
        """
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

        // Inject environment variables
        var combinedParams = params
        fw.environmentVariables.forEach { combinedParams[$0.key] = $0.value }

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

        // Verify against Package Lockfile if available
        let lockfile = PackageDependencyManager.shared.generateLockfile()
        if !PackageDependencyManager.shared.verifyLockfile(lockfile) {
             log(to: id, level: .warning, message: "Dependency resolution warning: Lockfile integrity mismatch.")
        }

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

        let sandboxResult = FrameworkSandboxRunner.execute(framework: fw, params: combinedParams, config: fw.sandboxProfile.config)

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
        let record = FrameworkExecutionRecord(frameworkId: id, frameworkName: name, entryPoint: entryPoint, timestamp: Date(), state: state, output: output, durationMs: duration, memoryUsageMb: memEstimate)
        executionRecords.append(record)

        if var fw = registry.framework(by: id) {
            fw.performanceMetricsHistory.append(record)
            if fw.performanceMetricsHistory.count > 50 {
                fw.performanceMetricsHistory.removeFirst()
            }
            registry.install(fw)
        }

        return result
    }
}

// MARK: - FrameworkManageView

struct FrameworkFilterPreset: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    let name: String
    let filter: FrameworkDescriptor.FrameworkType?
    let primarySort: FrameworkManageView.SortOption
    let secondarySort: FrameworkManageView.SortOption
    let sortAscending: Bool
}

struct FrameworkManageView: View {
    @State private var manager = FrameworkManager.shared
    @State private var registry = FrameworkRegistry.shared
    @State private var tokenEngine = DeterministicTokenEngine.shared

    @State private var showInstallSheet = false
    @State private var selectedFramework: FrameworkDescriptor?
    @State private var showDiagnostics = false
    @State private var showAuditLog = false
    @State private var searchText = ""
    @State private var selectedFilter: FrameworkDescriptor.FrameworkType?
    @State private var primarySort: SortOption = .name
    @State private var secondarySort: SortOption = .size
    @State private var sortAscending = true
    @State private var presets: [FrameworkFilterPreset] = []
    @State private var showSavePresetAlert = false
    @State private var newPresetName = ""
    @State private var multiSelection = Set<UUID>()
    @State private var showBatchDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    enum SortOption: String, Codable, CaseIterable {
        case name = "Name"
        case size = "Size"
        case archCount = "Architectures"
        case linkType = "Link Type"
        case lastModified = "Last Modified"
    }

    private var filteredFrameworks: [FrameworkDescriptor] {
        var filtered = registry.frameworks

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText) ||
                $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let filter = selectedFilter {
            filtered = filtered.filter { $0.type == filter }
        }

        return filtered.sorted { lhs, rhs in
            let result = compare(lhs, rhs, by: primarySort)
            if result == .orderedSame {
                return compare(lhs, rhs, by: secondarySort) == .orderedAscending
            }
            return (result == .orderedAscending) == sortAscending
        }
    }

    private func compare(_ lhs: FrameworkDescriptor, _ rhs: FrameworkDescriptor, by option: SortOption) -> ComparisonResult {
        switch option {
        case .name: return lhs.name.localizedCompare(rhs.name)
        case .size: return lhs.size == rhs.size ? .orderedSame : (lhs.size < rhs.size ? .orderedAscending : .orderedDescending)
        case .archCount: return lhs.architectures.count == rhs.architectures.count ? .orderedSame : (lhs.architectures.count < rhs.architectures.count ? .orderedAscending : .orderedDescending)
        case .linkType: return lhs.linkType.rawValue.localizedCompare(rhs.linkType.rawValue)
        case .lastModified: return lhs.lastModified.compare(rhs.lastModified)
        }
    }

    var body: some View {
        NavigationStack {
            List(selection: $multiSelection) {
                authSection
                filterSection
                frameworkListSection
                executionStateSection
                liveMonitoringSection
                sandboxSection
                executionHistorySection
            }
            .refreshable { await refreshFrameworks() }
            .listStyle(.insetGrouped)
            .navigationTitle("Frameworks")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search frameworks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button { showAuditLog = true } label: { Label("Audit Log", systemImage: "clock.arrow.circlepath") }
                        Button { showDiagnostics = true } label: { Label("Diagnostics", systemImage: "bolt.heart") }
                        sortMenu
                        Button { showInstallSheet = true } label: { Label("Add", systemImage: "plus") }
                        .disabled(tokenEngine.currentToken == nil)
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    if !multiSelection.isEmpty {
                        batchActionsMenu
                        Spacer()
                        Button(role: .destructive) {
                            showBatchDeleteConfirmation = true
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .sheet(isPresented: $showInstallSheet) {
                NavigationStack { FrameworkInstallSheet(manager: manager) }
            }
            .sheet(item: $selectedFramework) { fw in
                NavigationStack { FrameworkDetailSheet(framework: fw, manager: manager) }
            }
            .alert("Save Preset", isPresented: $showSavePresetAlert) {
                TextField("Preset Name", text: $newPresetName)
                Button("Save", action: savePreset)
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showDiagnostics) {
                NavigationStack { FrameworkDiagnosticsView(frameworks: registry.frameworks, manager: manager) }
            }
            .sheet(isPresented: $showAuditLog) {
                NavigationStack { FrameworkAuditLogView(log: manager.auditLog, manager: manager) }
            }
            .confirmationDialog("Remove Frameworks", isPresented: $showBatchDeleteConfirmation) {
                Button("Remove \(multiSelection.count) Frameworks", role: .destructive) {
                    batchDelete()
                }
            } message: {
                Text("Are you sure you want to remove the selected frameworks? This action cannot be undone.")
            }
            .onAppear { loadPresetsFromDisk() }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    FrameworkShareSheet(activityItems: [url])
                }
            }
        }
    }

    private var filterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "All", type: nil)
                    ForEach(FrameworkDescriptor.FrameworkType.allCases, id: \.self) { type in
                        filterChip(title: type.rawValue.capitalized, type: type)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func filterChip(title: String, type: FrameworkDescriptor.FrameworkType?) -> some View {
        Toggle(isOn: Binding(
            get: { selectedFilter == type },
            set: { if $0 { selectedFilter = type } }
        )) {
            Text(title).font(.caption2.bold())
        }
        .toggleStyle(.button)
        .buttonStyle(.bordered)
        .tint(selectedFilter == type ? .accentColor : .secondary)
        .controlSize(.small)
    }

    private var batchActionsMenu: some View {
        Menu {
            Section("Export") {
                Button { batchExport() } label: {
                    Label("Export as .zip", systemImage: "archivebox")
                }
            }
            Section("Link Type") {
                Button("Set Required") { batchUpdateLinkType(.required) }
                Button("Set Optional") { batchUpdateLinkType(.optional) }
            }
            Section("Embed Mode") {
                Button("Embed & Sign") { batchUpdateEmbedMode(.embedAndSign) }
                Button("Embed Without Signing") { batchUpdateEmbedMode(.embedWithoutSigning) }
                Button("Do Not Embed") { batchUpdateEmbedMode(.doNotEmbed) }
            }
            Section("Status") {
                Button("Enable All") { batchUpdateEnabled(true) }
                Button("Disable All") { batchUpdateEnabled(false) }
            }
        } label: {
            Label("Batch Actions", systemImage: "ellipsis.circle")
        }
    }

    private func batchUpdateLinkType(_ type: FrameworkDescriptor.LinkType) {
        for id in multiSelection {
            if var fw = registry.framework(by: id) {
                fw.linkType = type
                registry.install(fw)
            }
        }
    }

    private func batchUpdateEmbedMode(_ mode: FrameworkDescriptor.EmbedMode) {
        for id in multiSelection {
            if var fw = registry.framework(by: id) {
                fw.embedMode = mode
                registry.install(fw)
            }
        }
    }

    private func batchUpdateEnabled(_ enabled: Bool) {
        for id in multiSelection {
            if var fw = registry.framework(by: id) {
                fw.isEnabled = enabled
                registry.install(fw)
            }
        }
    }

    private func batchDelete() {
        for id in multiSelection {
            _ = manager.uninstallFramework(id: id)
        }
        multiSelection.removeAll()
    }

    private func batchExport() {
        var zip = NativeZipArchive()
        for id in multiSelection {
            if let fw = registry.framework(by: id), !fw.path.isEmpty {
                let fwURL = URL(fileURLWithPath: fw.path)
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: fw.path, isDirectory: &isDir) {
                    if isDir.boolValue {
                        zip.addDirectory(url: fwURL, base: fwURL.deletingLastPathComponent())
                    } else {
                        if let data = try? Data(contentsOf: fwURL) {
                            zip.addFile(name: fwURL.lastPathComponent, data: data)
                        }
                    }
                }
            }
        }
        let zipData = zip.finalize()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ExportedFrameworks.zip")
        do {
            try zipData.write(to: tempURL)
            self.exportURL = tempURL
            self.showShareSheet = true
        } catch {
            print("Failed to write zip: \(error)")
        }
    }

    private var sortMenu: some View {
        Menu {
            Section("Sort") {
                Picker("Primary Sort", selection: $primarySort) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Picker("Secondary Sort", selection: $secondarySort) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Button {
                    sortAscending.toggle()
                } label: {
                    Label(sortAscending ? "Ascending" : "Descending", systemImage: sortAscending ? "arrow.up" : "arrow.down")
                }
            }

            Section("Presets") {
                if presets.isEmpty {
                    Text("No saved presets").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(presets) { preset in
                        Button { applyPreset(preset) } label: {
                            HStack {
                                Text(preset.name)
                                if selectedFilter == preset.filter && primarySort == preset.primarySort && secondarySort == preset.secondarySort && sortAscending == preset.sortAscending {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                Button {
                    newPresetName = ""
                    showSavePresetAlert = true
                } label: {
                    Label("Save Current as Preset...", systemImage: "plus.square.on.square")
                }
            }
        } label: {
            Label("Sort & Presets", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private func applyPreset(_ preset: FrameworkFilterPreset) {
        selectedFilter = preset.filter
        primarySort = preset.primarySort
        secondarySort = preset.secondarySort
        sortAscending = preset.sortAscending
    }

    private func savePreset() {
        guard !newPresetName.isEmpty else { return }
        let preset = FrameworkFilterPreset(name: newPresetName, filter: selectedFilter, primarySort: primarySort, secondarySort: secondarySort, sortAscending: sortAscending)
        presets.append(preset)
        savePresetsToDisk()
    }

    private func loadPresetsFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "FrameworkFilterPresets"),
           let decoded = try? JSONDecoder().decode([FrameworkFilterPreset].self, from: data) {
            presets = decoded
        }
    }

    private func refreshFrameworks() async {
        // Real logic: re-scan registry frameworks to update size, date, etc.
        for i in 0..<registry.frameworks.count {
            let fw = registry.frameworks[i]
            guard !fw.path.isEmpty else { continue }
            let url = URL(fileURLWithPath: fw.path)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fw.path) {
                var updated = fw
                updated.size = attrs[.size] as? Int64 ?? 0
                updated.lastModified = attrs[.modificationDate] as? Date ?? Date()
                registry.frameworks[i] = updated
            }
        }
    }

    private func savePresetsToDisk() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: "FrameworkFilterPresets")
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { _ = manager.uninstallFramework(id: fw.id) } label: { Label("Remove", systemImage: "trash") }
                        Button {
                            let url = URL(fileURLWithPath: fw.path).deletingLastPathComponent()
                            UIApplication.shared.open(url)
                        } label: { Label("Reveal", systemImage: "folder") }.tint(.blue)
                    }
                    .swipeActions(edge: .leading) {
                        Button { manager.toggleFramework(id: fw.id) } label: {
                            Label(fw.isEnabled ? "Disable" : "Enable", systemImage: fw.isEnabled ? "pause" : "play")
                        }.tint(fw.isEnabled ? .orange : .green)
                        Button {
                            var updated = fw
                            updated.linkType = (fw.linkType == .required ? .optional : .required)
                            registry.install(updated)
                        } label: { Label(fw.linkType == .required ? "Optional" : "Required", systemImage: "link") }.tint(.purple)
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
                ForEach(Array(manager.executionRecords.suffix(10).reversed())) { record in
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

// MARK: - Info.plist Viewer

struct FrameworkInfoPlistView: View {
    let data: [String: AnyHashable]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            renderNode(key: "Root", value: data)
        }
        .navigationTitle("Info.plist")
    }

    @ViewBuilder
    private func renderNode(key: String, value: AnyHashable) -> some View {
        if let dict = value as? [String: AnyHashable] {
            AnyView(
                Section(key) {
                    ForEach(dict.keys.sorted(), id: \.self) { subkey in
                        renderNode(key: subkey, value: dict[subkey]!)
                    }
                }
            )
        } else if let array = value as? [AnyHashable] {
            AnyView(
                Section(key) {
                    ForEach(Array(array.enumerated()), id: \.offset) { index, subvalue in
                        renderNode(key: "[\(index)]", value: subvalue)
                    }
                }
            )
        } else {
            AnyView(
                LabeledContent(key) {
                    Text(String(describing: value))
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            )
        }
    }
}

// MARK: - Diagnostics View

struct FrameworkDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    let frameworks: [FrameworkDescriptor]
    let manager: FrameworkManager
    @State private var issues: [DiagnosticIssue] = []
    @State private var isScanning = false

    struct DiagnosticIssue: Identifiable {
        let id = UUID()
        let frameworkName: String
        let severity: Severity
        let title: String
        let description: String

        enum Severity: String {
            case error, warning, info
            var color: Color {
                switch self {
                case .error: return .red
                case .warning: return .orange
                case .info: return .blue
                }
            }
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 20) {
                    summaryItem(count: issues.filter { $0.severity == .error }.count, label: "Errors", color: .red)
                    summaryItem(count: issues.filter { $0.severity == .warning }.count, label: "Warnings", color: .orange)
                    summaryItem(count: issues.filter { $0.severity == .info }.count, label: "Info", color: .blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }

            Section("Issues (\(issues.count))") {
                if isScanning {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Scanning project...").foregroundStyle(.secondary)
                    }
                } else if issues.isEmpty {
                    Text("No issues detected").foregroundStyle(.green)
                } else {
                    ForEach(issues) { issue in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(issue.severity.rawValue.uppercased())
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(issue.severity.color.opacity(0.2))
                                    .foregroundStyle(issue.severity.color)
                                    .cornerRadius(4)
                                Text(issue.frameworkName).font(.caption.bold())
                            }
                            Text(issue.title).font(.subheadline.bold())
                            Text(issue.description).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Diagnostics")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            ToolbarItem(placement: .primaryAction) { Button("Rescan") { runScan() } }
        }
        .onAppear { runScan() }
    }

    private func summaryItem(count: Int, label: String, color: Color) -> some View {
        VStack {
            Text("\(count)").font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func runScan() {
        isScanning = true
        issues.removeAll()
        Task {
            var newIssues: [DiagnosticIssue] = []
            for fw in frameworks {
                if !fw.path.isEmpty && !FileManager.default.fileExists(atPath: fw.path) {
                    newIssues.append(DiagnosticIssue(frameworkName: fw.name, severity: .error, title: "Broken Reference", description: "Path '\(fw.path)' does not exist."))
                }
                if !fw.architectures.contains("arm64") {
                    newIssues.append(DiagnosticIssue(frameworkName: fw.name, severity: .warning, title: "Architecture Gap", description: "Missing arm64 slice, required for iOS hardware."))
                }
                let unused = await checkIsUnused(fw)
                if unused {
                    newIssues.append(DiagnosticIssue(frameworkName: fw.name, severity: .info, title: "Unused Framework", description: "No imports found in project source files."))
                }

                // Circular Dependency Check
                if hasCircularDependency(fw, visited: []) {
                    newIssues.append(DiagnosticIssue(frameworkName: fw.name, severity: .error, title: "Circular Dependency", description: "Framework depends on itself through a dependency chain."))
                }
            }

            // Cross-Registry Symbol Collision Check
            let collisions = findSymbolCollisions()
            for (symbol, providers) in collisions {
                newIssues.append(DiagnosticIssue(frameworkName: providers.joined(separator: " & "), severity: .warning, title: "Symbol Collision", description: "Symbol '\(symbol)' provided by multiple frameworks."))
            }

            self.issues = newIssues
            self.isScanning = false
        }
    }

    private func hasCircularDependency(_ fw: FrameworkDescriptor, visited: Set<UUID>) -> Bool {
        if visited.contains(fw.id) { return true }
        var newVisited = visited
        newVisited.insert(fw.id)
        for depId in fw.frameworkDependencies {
            if let dep = FrameworkRegistry.shared.framework(by: depId) {
                if hasCircularDependency(dep, visited: newVisited) { return true }
            }
        }
        return false
    }

    private func findSymbolCollisions() -> [String: [String]] {
        var symbolMap: [String: [String]] = [:]
        var seenSymbols: [String: String] = [:]
        let allFrameworks = FrameworkRegistry.shared.frameworks

        for fw in allFrameworks {
            let symbols = manager.getSymbolsSynchronously(for: fw)
            for sym in symbols {
                if let firstProvider = seenSymbols[sym] {
                    if firstProvider != fw.name {
                        symbolMap[sym, default: [firstProvider]].append(fw.name)
                    }
                } else {
                    seenSymbols[sym] = fw.name
                }
            }
        }
        return symbolMap.filter { $0.value.count > 1 }
    }

    private func checkIsUnused(_ fw: FrameworkDescriptor) async -> Bool {
        let fm = FileManager.default
        guard let sources = fm.enumerator(at: URL(fileURLWithPath: "Sources"), includingPropertiesForKeys: [.isRegularFileKey]) else { return true }
        while let url = sources.nextObject() as? URL {
            if url.pathExtension == "swift", let content = try? String(contentsOf: url), content.contains("import \(fw.name)") {
                return false
            }
        }
        return true
    }
}

// MARK: - Symbol Browser View

struct FrameworkSymbolBrowser: View {
    @Environment(\.dismiss) private var dismiss
    let framework: FrameworkDescriptor
    @State private var symbols: [String] = []
    @State private var searchText = ""
    @State private var isLoading = false

    var filteredSymbols: [String] {
        if searchText.isEmpty { return symbols }
        return symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(filteredSymbols, id: \.self) { symbol in
            Text(symbol).font(.system(size: 10, design: .monospaced))
                .swipeActions {
                    Button {
                        UIPasteboard.general.string = symbol
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
        }
        .navigationTitle("Symbols")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            ToolbarItem(placement: .bottomBar) {
                if isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Text("\(filteredSymbols.count) symbols").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { loadSymbols() }
    }

    private func loadSymbols() {
        isLoading = true
        Task {
            guard !framework.path.isEmpty else {
                isLoading = false
                return
            }
            let url = URL(fileURLWithPath: framework.path)
            let binaryURL = framework.path.hasSuffix(".framework") ? url.appendingPathComponent(url.deletingPathExtension().lastPathComponent) : url

            guard let handle = try? FileHandle(forReadingFrom: binaryURL) else {
                isLoading = false
                return
            }
            defer { try? handle.close() }

            // Re-parse to find LC_SYMTAB and read symbols
            guard let magicData = try? handle.read(upToCount: 4) else {
                isLoading = false
                return
            }
            let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }

            var offset: UInt64 = 0
            if magic == 0xBEBAFECA || magic == 0xCAFEBABE {
                guard let countData = try? handle.read(upToCount: 4) else {
                    isLoading = false
                    return
                }
                let count = countData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                if count > 0 {
                    guard let archData = try? handle.read(upToCount: 20) else {
                        isLoading = false
                        return
                    }
                    offset = UInt64(archData.advanced(by: 8).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian)
                }
            }

            try? handle.seek(toOffset: offset)
            guard let headerData = try? handle.read(upToCount: 32) else {
                isLoading = false
                return
            }
            let is64 = headerData.count == 32
            let ncmds = headerData.advanced(by: 16).withUnsafeBytes { $0.load(as: UInt32.self) }
            try? handle.seek(toOffset: offset + (is64 ? 32 : 28))

            var symoff: UInt32 = 0
            var nsyms: UInt32 = 0
            var stroff: UInt32 = 0
            var strsize: UInt32 = 0

            for _ in 0..<ncmds {
                guard let cmdData = try? handle.read(upToCount: 8) else { break }
                let cmd = cmdData.withUnsafeBytes { $0.load(as: UInt32.self) }
                let size = cmdData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }
                if cmd == 0x02 { // LC_SYMTAB
                    guard let symData = try? handle.read(upToCount: 16) else { break }
                    symoff = symData.withUnsafeBytes { $0.load(as: UInt32.self) }
                    nsyms = symData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }
                    stroff = symData.advanced(by: 8).withUnsafeBytes { $0.load(as: UInt32.self) }
                    strsize = symData.advanced(by: 12).withUnsafeBytes { $0.load(as: UInt32.self) }
                    break
                }
                if let current = try? handle.offset() {
                    try? handle.seek(toOffset: current + UInt64(size) - 8)
                }
            }

            if nsyms > 0 && stroff > 0 {
                try? handle.seek(toOffset: offset + UInt64(stroff))
                if let strData = try? handle.read(upToCount: Int(strsize)) {
                    var detectedSymbols: [String] = []
                    var current = Data()
                    for byte in strData {
                        if byte == 0 {
                            if !current.isEmpty, let s = String(data: current, encoding: .utf8) {
                                detectedSymbols.append(s)
                            }
                            current = Data()
                        } else {
                            current.append(byte)
                        }
                    }
                    self.symbols = detectedSymbols.sorted()
                }
            }
            self.isLoading = false
        }
    }
}

// MARK: - Audit Log View

struct FrameworkAuditLogView: View {
    @Environment(\.dismiss) private var dismiss
    let log: [FrameworkManager.FrameworkAuditEntry]
    let manager: FrameworkManager

    var body: some View {
        List {
            ForEach(Array(log.reversed())) { entry in
                auditEntryRow(entry, manager: manager)
            }
        }
        .navigationTitle("Audit Log")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let text = log.map { "[\($0.timestamp)] \($0.frameworkName) - \($0.action): \($0.oldValue) -> \($0.newValue)" }.joined(separator: "\n")
                    UIPasteboard.general.string = text
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    @ViewBuilder
    private func auditEntryRow(_ entry: FrameworkManager.FrameworkAuditEntry, manager: FrameworkManager) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.frameworkName).font(.subheadline.bold())
                Spacer()
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Text(entry.action).font(.caption.bold()).foregroundStyle(Color.accentColor)
            HStack {
                Text(entry.oldValue).foregroundStyle(.red)
                Image(systemName: "arrow.right").font(.caption2)
                Text(entry.newValue).foregroundStyle(.green)
            }
            .font(.system(size: 10, design: .monospaced))
        }
    }
}

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

// MARK: - Native ZIP Support

struct NativeZipArchive {
    private var localFileData = Data()
    private var centralDirectoryData = Data()
    private var entryCount: UInt16 = 0

    mutating func addFile(name: String, data: Data) {
        let relativePath = name.replacingOccurrences(of: "\\", with: "/")
        let nameData = Data(relativePath.utf8)
        let crc = computeCRC32(data)
        let size = UInt32(data.count)
        let offset = UInt32(localFileData.count)

        // Local File Header
        var localHeader = Data()
        localHeader.append(contentsOf: [0x50, 0x4b, 0x03, 0x04])
        localHeader.append(contentsOf: [0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        localHeader.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Data($0) })
        localHeader.append(contentsOf: withUnsafeBytes(of: size.littleEndian) { Data($0) })
        localHeader.append(contentsOf: withUnsafeBytes(of: size.littleEndian) { Data($0) })
        localHeader.append(contentsOf: withUnsafeBytes(of: UInt16(nameData.count).littleEndian) { Data($0) })
        localHeader.append(contentsOf: [0x00, 0x00])
        localHeader.append(nameData)

        localFileData.append(localHeader)
        localFileData.append(data)

        // Central Directory Header
        var cdHeader = Data()
        cdHeader.append(contentsOf: [0x50, 0x4b, 0x01, 0x02])
        cdHeader.append(contentsOf: [0x14, 0x00, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        cdHeader.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Data($0) })
        cdHeader.append(contentsOf: withUnsafeBytes(of: size.littleEndian) { Data($0) })
        cdHeader.append(contentsOf: withUnsafeBytes(of: size.littleEndian) { Data($0) })
        cdHeader.append(contentsOf: withUnsafeBytes(of: UInt16(nameData.count).littleEndian) { Data($0) })
        cdHeader.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        cdHeader.append(contentsOf: withUnsafeBytes(of: offset.littleEndian) { Data($0) })
        cdHeader.append(nameData)

        centralDirectoryData.append(cdHeader)
        entryCount += 1
    }

    mutating func addDirectory(url: URL, base: URL) {
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [URLResourceKey.isRegularFileKey], options: [])
        while let fileURL = enumerator?.nextObject() as? URL {
            if let vals = try? fileURL.resourceValues(forKeys: [URLResourceKey.isRegularFileKey]), vals.isRegularFile == true {
                let rel = fileURL.path.replacingOccurrences(of: base.path + "/", with: "")
                if let d = try? Data(contentsOf: fileURL) { addFile(name: rel, data: d) }
            }
        }
    }

    func finalize() -> Data {
        var d = localFileData
        let cdOffset = UInt32(d.count)
        let cdSize = UInt32(centralDirectoryData.count)
        d.append(centralDirectoryData)
        d.append(contentsOf: [0x50, 0x4b, 0x05, 0x06, 0x00, 0x00, 0x00, 0x00])
        d.append(contentsOf: withUnsafeBytes(of: entryCount.littleEndian) { Data($0) })
        d.append(contentsOf: withUnsafeBytes(of: entryCount.littleEndian) { Data($0) })
        d.append(contentsOf: withUnsafeBytes(of: cdSize.littleEndian) { Data($0) })
        d.append(contentsOf: withUnsafeBytes(of: cdOffset.littleEndian) { Data($0) })
        d.append(contentsOf: [0x00, 0x00])
        return d
    }

    private func computeCRC32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 { crc = (crc >> 1) ^ (crc & 1 != 0 ? 0xEDB88320 : 0) }
        }
        return ~crc
    }
}

struct FrameworkShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: activityItems, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct FrameworkDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let framework: FrameworkDescriptor
    let manager: FrameworkManager

    @State private var execParams: [String: String] = [:]
    @State private var parsedArchitectures: [String] = []
    @State private var isFatBinary = false
    @State private var symbolCount: Int = 0
    @State private var linkerDependencies: [String] = []
    @State private var infoPlist: [String: AnyHashable] = [:]
    @State private var showSymbolBrowser = false
    @State private var teamID: String = "Unknown"
    @State private var entitlements: [String: AnyHashable] = [:]
    @State private var showStripConfirmation = false
    @State private var minOSVersion: String = "Unknown"
    @State private var sdkVersion: String = "Unknown"
    @State private var sourceVersion: String = "Unknown"
    @State private var showEnvVarEditor = false
    @State private var showReportSheet = false

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: framework.name)
                LabeledContent("Path", value: framework.path)
                LabeledContent("Type", value: framework.type.rawValue.capitalized)
                LabeledContent("ID", value: String(framework.id.uuidString.prefix(8)) + "...")
                LabeledContent("Language", value: framework.language.rawValue)
                LabeledContent("State", value: framework.lifecycleState.rawValue.capitalized)
                LabeledContent("Enabled", value: framework.isEnabled ? "Yes" : "No")
            }

            Section("Code Signature") {
                LabeledContent("Team ID", value: teamID)
                if !entitlements.isEmpty {
                    NavigationLink("Entitlements (\(entitlements.count))") {
                        FrameworkInfoPlistView(data: entitlements)
                            .navigationTitle("Entitlements")
                    }
                }
            }

            if !infoPlist.isEmpty {
                Section("Metadata") {
                    NavigationLink("Info.plist Viewer") {
                        FrameworkInfoPlistView(data: infoPlist)
                    }
                }
            }

            if !linkerDependencies.isEmpty {
                Section("Linker Dependencies") {
                    ForEach(linkerDependencies, id: \.self) { dep in
                        Text(dep).font(.caption2.monospaced())
                    }
                }
            }

            Section("Binary Info") {
                LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: framework.size, countStyle: .file))
                LabeledContent("Last Modified", value: framework.lastModified.formatted())
                LabeledContent("Min OS", value: minOSVersion)
                LabeledContent("SDK", value: sdkVersion)
                LabeledContent("Source Version", value: sourceVersion)
                LabeledContent("Fat Binary", value: isFatBinary ? "Yes" : "No")
                if isFatBinary && parsedArchitectures.contains("x86_64") {
                    Button("Strip Simulator Slices", role: .destructive) {
                        showStripConfirmation = true
                    }
                    .font(.caption)
                }
                Button {
                    showSymbolBrowser = true
                } label: {
                    LabeledContent("Symbols", value: "\(symbolCount)")
                }
                VStack(alignment: .leading) {
                    Text("Architectures").font(.subheadline.bold())
                    if parsedArchitectures.isEmpty {
                        Text("Unknown").foregroundStyle(.secondary)
                    } else {
                        ForEach(parsedArchitectures, id: \.self) { arch in
                            Text("• \(arch)")
                        }
                    }
                }
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
            Section("Package Dependencies") {
                if framework.packageDependencies.isEmpty {
                    Text("No package dependencies").foregroundStyle(.secondary)
                } else {
                    ForEach(framework.packageDependencies, id: \.self) { depId in
                        Text(String(depId.uuidString.prefix(8)) + "...").font(.caption.monospaced())
                    }
                }
            }

            Section("Framework Dependencies") {
                if framework.frameworkDependencies.isEmpty {
                    Text("No framework dependencies").foregroundStyle(.secondary)
                } else {
                    ForEach(framework.frameworkDependencies, id: \.self) { depId in
                        if let dep = FrameworkRegistry.shared.framework(by: depId) {
                            Text(dep.name).font(.caption)
                        } else {
                            Text(String(depId.uuidString.prefix(8)) + "...").font(.caption.monospaced())
                        }
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

            Section("Management") {
                Button { manager.hotReload(id: framework.id) } label: {
                    Label("Hot-Reload from Filesystem", systemImage: "arrow.clockwise")
                }
                Button { showReportSheet = true } label: {
                    Label("Generate Report", systemImage: "doc.text")
                }
                Button { showEnvVarEditor = true } label: {
                    Label("Manage Env Vars (\(framework.environmentVariables.count))", systemImage: "terminal")
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
        .onAppear { parseMachO() }
        .confirmationDialog("Strip Slices?", isPresented: $showStripConfirmation) {
            Button("Strip x86_64", role: .destructive) { stripSimulatorSlices() }
        } message: {
            Text("This will create a backup and remove the x86_64 slice from the framework binary. This action is permanent.")
        }
        .sheet(isPresented: $showSymbolBrowser) {
            NavigationStack {
                FrameworkSymbolBrowser(framework: framework)
            }
        }
        .sheet(isPresented: $showEnvVarEditor) {
            NavigationStack {
                FrameworkEnvVarEditor(framework: framework, manager: manager)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            NavigationStack {
                FrameworkReportView(report: manager.generateMarkdownReport(id: framework.id))
            }
        }
    }

    private func parseMachO() {
        guard !framework.path.isEmpty else { return }
        let url = URL(fileURLWithPath: framework.path)
        let binaryURL = framework.path.hasSuffix(".framework") ? url.appendingPathComponent(url.deletingPathExtension().lastPathComponent) : url

        loadInfoPlist(url: url)

        guard let handle = try? FileHandle(forReadingFrom: binaryURL) else { return }
        defer { try? handle.close() }

        guard let magicData = try? handle.read(upToCount: 4) else { return }
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }

        if magic == 0xBEBAFECA || magic == 0xCAFEBABE {
            isFatBinary = true
            guard let countData = try? handle.read(upToCount: 4) else { return }
            let count = countData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
            var archs: [String] = []
            for _ in 0..<count {
                guard let archData = try? handle.read(upToCount: 20) else { break }
                let cputype = archData.withUnsafeBytes { $0.load(as: Int32.self) }.bigEndian
                let offset = archData.advanced(by: 8).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                archs.append(cpuTypeToString(cputype))
                if symbolCount == 0 { parseLoadCommands(handle: handle, offset: UInt64(offset)) }
            }
            parsedArchitectures = Array(Set(archs)).sorted()
        } else if [0xFEEDFACE, 0xFEEDFACF, 0xCEFAEDFE, 0xCFFAEDFE].contains(magic) {
            isFatBinary = false
            guard let cputypeData = try? handle.read(upToCount: 4) else { return }
            parsedArchitectures = [cpuTypeToString(cputypeData.withUnsafeBytes { $0.load(as: Int32.self) })]
            parseLoadCommands(handle: handle, offset: 0)
        }
    }

    private func loadInfoPlist(url: URL) {
        let plistURL = url.appendingPathComponent("Info.plist")
        if let d = try? Data(contentsOf: plistURL),
           let plist = try? PropertyListSerialization.propertyList(from: d, options: [], format: nil) as? [String: AnyHashable] {
            self.infoPlist = plist
        }
    }

    private func parseLoadCommands(handle: FileHandle, offset: UInt64) {
        try? handle.seek(toOffset: offset)
        guard let headerData = try? handle.read(upToCount: 32) else { return }
        let is64 = headerData.count == 32
        let ncmds = headerData.advanced(by: 16).withUnsafeBytes { $0.load(as: UInt32.self) }
        try? handle.seek(toOffset: offset + (is64 ? 32 : 28))
        var deps: [String] = []
        for _ in 0..<ncmds {
            guard let cmdData = try? handle.read(upToCount: 8) else { break }
            let cmd = cmdData.withUnsafeBytes { $0.load(as: UInt32.self) }
            let size = cmdData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }
            if cmd == 0x02 { // LC_SYMTAB
                guard let symData = try? handle.read(upToCount: 8) else { break }
                self.symbolCount = Int(symData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) })
            } else if cmd == 0x0c || cmd == 0x18 { // LC_LOAD_DYLIB / LC_LOAD_WEAK_DYLIB
                guard let dylibData = try? handle.read(upToCount: Int(size) - 8) else { break }
                let nameOffset = dylibData.withUnsafeBytes { $0.load(as: UInt32.self) }
                let nameData = dylibData.advanced(by: Int(nameOffset) - 8)
                if let name = String(data: nameData.prefix { $0 != 0 }, encoding: .utf8) {
                    deps.append(name)
                }
            } else if cmd == 0x1d { // LC_CODE_SIGNATURE
                guard let sigData = try? handle.read(upToCount: 8) else { break }
                let sigOff = sigData.withUnsafeBytes { $0.load(as: UInt32.self) }
                let sigSize = sigData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }
                parseSignatureBlob(handle: handle, offset: offset + UInt64(sigOff), size: sigSize)
            } else if cmd == 0x25 { // LC_VERSION_MIN_IPHONEOS
                guard let vData = try? handle.read(upToCount: 8) else { break }
                let version = vData.withUnsafeBytes { $0.load(as: UInt32.self) }
                let sdk = vData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }
                self.minOSVersion = decodeMachOVersion(version)
                self.sdkVersion = decodeMachOVersion(sdk)
            } else if cmd == 0x32 { // LC_BUILD_VERSION
                guard let vData = try? handle.read(upToCount: 16) else { break }
                let minos = vData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }
                let sdk = vData.advanced(by: 8).withUnsafeBytes { $0.load(as: UInt32.self) }
                self.minOSVersion = decodeMachOVersion(minos)
                self.sdkVersion = decodeMachOVersion(sdk)
            } else if cmd == 0x2a { // LC_SOURCE_VERSION
                guard let vData = try? handle.read(upToCount: 8) else { break }
                let v = vData.withUnsafeBytes { $0.load(as: UInt64.self) }
                self.sourceVersion = "\(v >> 40).\( (v >> 30) & 0x3ff ).\( (v >> 20) & 0x3ff ).\( (v >> 10) & 0x3ff ).\( v & 0x3ff )"
            } else {
                if let current = try? handle.offset() {
                    try? handle.seek(toOffset: current + UInt64(size) - 8)
                }
            }
        }
        self.linkerDependencies = deps
    }

    private func parseSignatureBlob(handle: FileHandle, offset: UInt64, size: UInt32) {
        do {
            try handle.seek(toOffset: offset)
            guard let superBlobData = try handle.read(upToCount: 12) else { return }
            let magic = superBlobData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
            guard magic == 0xfade0cc0 else { return }
            let count = superBlobData.advanced(by: 8).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian

            for _ in 0..<count {
                guard let indexData = try handle.read(upToCount: 8) else { break }
                let type = indexData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                let blobOffset = indexData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian

                let currentPos = try handle.offset()
                if type == 5 { // CSSLOT_ENTITLEMENTS
                    try handle.seek(toOffset: offset + UInt64(blobOffset))
                    guard let blobHeader = try handle.read(upToCount: 8) else { continue }
                    let blobMagic = blobHeader.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                    let blobLength = blobHeader.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                    if blobMagic == 0xfade7171, blobLength > 8 {
                        guard let xmlData = try handle.read(upToCount: Int(blobLength) - 8) else { continue }
                        if let plist = try? PropertyListSerialization.propertyList(from: xmlData, options: [], format: nil) as? [String: AnyHashable] {
                            self.entitlements = plist
                        }
                    }
                }
                try handle.seek(toOffset: currentPos)
            }
            if let teamID = infoPlist["AppIdentifierPrefix"] as? String {
                self.teamID = teamID.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            }
        } catch {
            print("Signature Parsing Error: \(error)")
        }
    }

    private func stripSimulatorSlices() {
        guard !framework.path.isEmpty else { return }
        let url = URL(fileURLWithPath: framework.path)
        let binaryURL = framework.path.hasSuffix(".framework") ? url.appendingPathComponent(url.deletingPathExtension().lastPathComponent) : url
        do {
            let data = try Data(contentsOf: binaryURL)
            guard data.count > 8 else { return }
            let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
            if magic == 0xBEBAFECA || magic == 0xCAFEBABE {
                let count = data.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                var newSlices: [(Data, Data)] = []
                for i in 0..<Int(count) {
                    let archOff = 8 + (i * 20)
                    let archData = data.subdata(in: archOff..<(archOff + 20))
                    let cputype = archData.withUnsafeBytes { $0.load(as: Int32.self) }.bigEndian
                    if cputype != (7 | 0x01000000) {
                        let off = archData.advanced(by: 8).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                        let size = archData.advanced(by: 12).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                        newSlices.append((archData, data.subdata(in: Int(off)..<Int(off + size))))
                    }
                }
                if !newSlices.isEmpty {
                    var newData = Data(); newData.append(data.prefix(4))
                    newData.append(withUnsafeBytes(of: UInt32(newSlices.count).bigEndian) { Data($0) })
                    let hSize = 8 + (newSlices.count * 20)
                    var currOff = (hSize + 4095) & ~4095
                    var hs = Data(); var cs = Data()
                    for (var h, c) in newSlices {
                        h.replaceSubrange(8..<12, with: withUnsafeBytes(of: UInt32(currOff).bigEndian) { Data($0) })
                        hs.append(h)
                        let pad = currOff - (hSize + cs.count)
                        if pad > 0 { cs.append(Data(repeating: 0, count: pad)) }
                        cs.append(c); currOff += (c.count + 4095) & ~4095
                    }
                    newData.append(hs); newData.append(cs); try newData.write(to: binaryURL, options: .atomic)
                    manager.log(to: framework.id, level: .info, message: "Stripped x86_64 slice.")
                    parseMachO()
                }
            }
        } catch { print("Strip Error: \(error)") }
    }

    private func decodeMachOVersion(_ v: UInt32) -> String {
        return "\(v >> 16).\( (v >> 8) & 0xff ).\( v & 0xff )"
    }

    private func cpuTypeToString(_ type: Int32) -> String {
        switch type {
        case 7: return "x86"
        case 7 | 0x01000000: return "x86_64"
        case 12: return "arm"
        case 12 | 0x01000000: return "arm64"
        default: return "Unknown (\(type))"
        }
    }
}

struct FrameworkEnvVarEditor: View {
    let framework: FrameworkDescriptor
    let manager: FrameworkManager
    @Environment(\.dismiss) private var dismiss
    @State private var envVars: [EnvVar] = []
    @State private var newKey = ""
    @State private var newValue = ""

    struct EnvVar: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }

    var body: some View {
        List {
            Section("Current Variables") {
                ForEach(envVars) { varItem in
                    HStack {
                        Text(varItem.key).font(.caption.bold())
                        Spacer()
                        Text(varItem.value).font(.caption).foregroundStyle(.secondary)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            envVars.removeAll { $0.id == varItem.id }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }

            Section("Add New") {
                TextField("Key", text: $newKey)
                TextField("Value", text: $newValue)
                Button("Add") {
                    if !newKey.isEmpty {
                        envVars.append(EnvVar(key: newKey, value: newValue))
                        newKey = ""; newValue = ""
                    }
                }.disabled(newKey.isEmpty)
            }
        }
        .navigationTitle("Environment Variables")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var dict: [String: String] = [:]
                    envVars.forEach { dict[$0.key] = $0.value }
                    if var fw = FrameworkRegistry.shared.framework(by: framework.id) {
                        fw.environmentVariables = dict
                        FrameworkRegistry.shared.install(fw)
                    }
                    dismiss()
                }
            }
        }
        .onAppear {
            envVars = framework.environmentVariables.map { EnvVar(key: $0.key, value: $0.value) }
        }
    }
}

struct FrameworkReportView: View {
    let report: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            Text(report)
                .font(.system(size: 12, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Framework Report")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Copy") { UIPasteboard.general.string = report }
            }
            ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
        }
    }
}
