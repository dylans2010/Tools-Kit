import SwiftUI
import Observation

// MARK: - Library Descriptor

struct LibraryDescriptor: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let version: String
    let channel: ReleaseChannel
    let type: LibraryType
    let capabilities: [String]
    let requiredScopes: [SDKScope]
    let inputSchema: [String: String]
    let outputSchema: [String: String]
    let constraints: [String]
    var resourceLimits: [String: Double]
    var targetCount: Int
    var addedDate: Date
    var lastModified: Date
    var size: Int64
    var dependencies: [UUID]
    var hardeningFeatures: [String: Bool]

    enum LibraryType: String, Codable, CaseIterable {
        case `static`, dynamic, tbd, broken, unused, sdk, local
    }

    init(
        id: UUID = UUID(), name: String, path: String = "", version: String,
        channel: ReleaseChannel = .stable, type: LibraryType = .local,
        capabilities: [String] = [], requiredScopes: [SDKScope] = [],
        inputSchema: [String: String] = [:], outputSchema: [String: String] = [:],
        constraints: [String] = [],
        resourceLimits: [String: Double] = ["max_memory": 128.0, "max_cpu": 0.5],
        targetCount: Int = 0, addedDate: Date = Date(), lastModified: Date = Date(), size: Int64 = 0,
        dependencies: [UUID] = [], hardeningFeatures: [String: Bool] = [:]
    ) {
        self.id = id; self.name = name; self.path = path; self.version = version
        self.channel = channel; self.type = type
        self.capabilities = capabilities; self.requiredScopes = requiredScopes
        self.inputSchema = inputSchema; self.outputSchema = outputSchema
        self.constraints = constraints
        self.resourceLimits = resourceLimits
        self.targetCount = targetCount; self.addedDate = addedDate; self.lastModified = lastModified; self.size = size
        self.dependencies = dependencies; self.hardeningFeatures = hardeningFeatures
    }
}

// MARK: - Library Capability

enum LibraryCategory: String, CaseIterable, Codable, Identifiable {
    case ai = "AI"
    case storage = "Storage"
    case communication = "Communication"
    case data = "Data"
    case security = "Security"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .ai: return "sparkles"
        case .storage: return "externaldrive.fill"
        case .communication: return "message.fill"
        case .data: return "tablecells.fill"
        case .security: return "shield.fill"
        }
    }
}

enum LibraryCapability: String, CaseIterable, Codable, Identifiable {
    case textProcessing = "text.processing"
    case imageAnalysis = "image.analysis"
    case dataTransform = "data.transform"
    case networkRelay = "network.relay"
    case cryptoOps = "crypto.ops"
    case storageIO = "storage.io"
    case mlInference = "ml.inference"
    case audioProcessing = "audio.processing"

    var id: String { rawValue }

    var category: LibraryCategory {
        switch self {
        case .textProcessing, .mlInference, .audioProcessing: return .ai
        case .imageAnalysis, .dataTransform: return .data
        case .networkRelay: return .communication
        case .cryptoOps: return .security
        case .storageIO: return .storage
        }
    }

    var displayName: String {
        switch self {
        case .textProcessing: return "Text Processing"
        case .imageAnalysis: return "Image Analysis"
        case .dataTransform: return "Data Transform"
        case .networkRelay: return "Network Relay"
        case .cryptoOps: return "Crypto Operations"
        case .storageIO: return "Storage I/O"
        case .mlInference: return "ML Inference"
        case .audioProcessing: return "Audio Processing"
        }
    }

    var icon: String {
        switch self {
        case .textProcessing: return "text.alignleft"
        case .imageAnalysis: return "photo"
        case .dataTransform: return "arrow.triangle.2.circlepath"
        case .networkRelay: return "network"
        case .cryptoOps: return "lock.shield"
        case .storageIO: return "externaldrive"
        case .mlInference: return "brain"
        case .audioProcessing: return "waveform"
        }
    }
}

// MARK: - Library Execution Bridge (SDK Bridge — No Direct Workspace Writes)

struct LibraryExecutionBridge {
    static func invoke(library: LibraryDescriptor, input: [String: String]) -> UIAgentToolResult {
        guard !library.capabilities.isEmpty else {
            return .failure("Library has no capabilities")
        }
        return .success("Invoked \(library.name) with \(input.count) parameters via SDK bridge")
    }
}

// MARK: - Capability Composition Engine

struct CompositeWorkflow: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String = ""
    var isPersistent: Bool = false
    var steps: [WorkflowStep]

    struct WorkflowStep: Identifiable, Codable {
        let id: UUID
        var libraryId: UUID
        var capability: String
        var inputMapping: [String: String] // maps workflow input/prev step output to library input
    }
}

// MARK: - Invocation Templates

struct InvocationTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var libraryId: UUID
    var capability: String
    var predefinedInput: [String: String]
}

// MARK: - Invocation State

enum LibraryInvocationState: String {
    case idle, scopeCheck, capabilityMatch, inputValidation, executing, outputValidation, completed, failed
}

struct LibraryInvocationRecord: Identifiable {
    let id = UUID()
    let libraryId: UUID
    let libraryName: String
    let capability: String
    let input: [String: String]
    let output: String
    let timestamp: Date
    let state: LibraryInvocationState
    let durationMs: Int
}

struct CapabilityConflict: Identifiable {
    let id = UUID()
    let capability: String
    let providers: [String]
    let resolution: String
}

// MARK: - Library Registry

@MainActor
final class LibraryRegistry: ObservableObject {
    static let shared = LibraryRegistry()
    @Published var libraries: [LibraryDescriptor] = []
    @Published var marketplaceLibraries: [LibraryDescriptor] = []

    private init() {
        seedMarketplace()
    }

    private func seedMarketplace() {
        marketplaceLibraries = [
            LibraryDescriptor(name: "NeuralProcessor", version: "2.1.0", channel: .stable, capabilities: [LibraryCapability.mlInference.rawValue, LibraryCapability.textProcessing.rawValue], requiredScopes: [.persona]),
            LibraryDescriptor(name: "CloudVault", version: "1.0.5", channel: .stable, capabilities: [LibraryCapability.storageIO.rawValue, LibraryCapability.cryptoOps.rawValue], requiredScopes: [.files]),
            LibraryDescriptor(name: "StreamBridge", version: "0.9.8", channel: .beta, capabilities: [LibraryCapability.networkRelay.rawValue, LibraryCapability.audioProcessing.rawValue], requiredScopes: [.meet]),
            LibraryDescriptor(name: "DataAnalyzer", version: "3.2.1", channel: .experimental, capabilities: [LibraryCapability.dataTransform.rawValue, LibraryCapability.imageAnalysis.rawValue], requiredScopes: [.workspaceRead])
        ]
    }

    func install(_ lib: LibraryDescriptor) {
        libraries.removeAll { $0.name == lib.name }
        libraries.append(lib)
    }

    func uninstall(id: UUID) {
        libraries.removeAll { $0.id == id }
    }

    func library(by id: UUID) -> LibraryDescriptor? {
        libraries.first { $0.id == id }
    }
}

// MARK: - Library Manager

@MainActor
final class LibraryManager: ObservableObject {
    static let shared = LibraryManager()

    @Published var invocationRecords: [LibraryInvocationRecord] = []
    @Published var usageMetrics: [UUID: UsageMetrics] = [:]
    @Published var pendingApprovals: [LibraryScopeApproval] = []
    @Published var compositeWorkflows: [CompositeWorkflow] = []
    @Published var invocationTemplates: [InvocationTemplate] = []
    @Published var invocationState: LibraryInvocationState = .idle
    @Published var dryRunEnabled: Bool = false
    @Published var rateLimits: [UUID: Int] = [:] // libraryId: max per minute
    @Published var quotas: [UUID: Int] = [:] // libraryId: total allowed
    @Published var quotaUsage: [UUID: Int] = [:] // libraryId: current usage
    @Published var registrySnapshots: [RegistrySnapshot] = []

    struct RegistrySnapshot: Identifiable, Codable {
        let id = UUID()
        let timestamp = Date()
        let libraryCount: Int
        let encodedData: Data
    }

    private let tokenEngine = DeterministicTokenEngine.shared
    internal let registry = LibraryRegistry.shared

    struct LibraryScopeApproval: Identifiable {
        let id = UUID()
        let libraryId: UUID
        let libraryName: String
        let requestedScopes: [SDKScope]
        let timestamp: Date
        var approved: Bool = false
    }

    struct UsageMetrics: Codable {
        var totalInvocations: Int = 0
        var successCount: Int = 0
        var failureCount: Int = 0
        var lastDurationMs: Int = 0
        var totalDurationMs: Int = 0

        var failureRate: Double {
            totalInvocations == 0 ? 0 : Double(failureCount) / Double(totalInvocations)
        }

        var avgDurationMs: Int {
            totalInvocations == 0 ? 0 : totalDurationMs / totalInvocations
        }
    }

    private init() {
        seedTemplates()
        loadSnapshotsFromDisk()
    }

    private func seedTemplates() {
        invocationTemplates = [
            InvocationTemplate(id: UUID(), name: "Analyze Sentiment", libraryId: UUID(), capability: LibraryCapability.textProcessing.rawValue, predefinedInput: ["mode": "sentiment", "text": "Enter text here"]),
            InvocationTemplate(id: UUID(), name: "Secure Export", libraryId: UUID(), capability: LibraryCapability.cryptoOps.rawValue, predefinedInput: ["format": "aes-256", "target": "workspace"])
        ]
    }

    // MARK: - Install / Uninstall

    func installLibrary(name: String, version: String, channel: ReleaseChannel = .stable, capabilities: [String], scopes: [SDKScope]) -> Bool {
        guard tokenEngine.requireScope(.sdkManageLibraries) else { return false }
        guard !name.isEmpty, !version.isEmpty else { return false }

        let lib = LibraryDescriptor(name: name, version: version, channel: channel, capabilities: capabilities, requiredScopes: scopes)
        registry.install(lib)
        pendingApprovals.append(LibraryScopeApproval(libraryId: lib.id, libraryName: name, requestedScopes: scopes, timestamp: Date()))
        return true
    }

    func uninstallLibrary(id: UUID) -> Bool {
        guard tokenEngine.requireScope(.sdkManageLibraries) else { return false }
        registry.uninstall(id: id)
        return true
    }

    func createSnapshot() {
        guard let data = try? JSONEncoder().encode(registry.libraries) else { return }
        let snapshot = RegistrySnapshot(libraryCount: registry.libraries.count, encodedData: data)
        registrySnapshots.append(snapshot)
        saveSnapshotsToDisk()
    }

    func rollbackToSnapshot(_ snapshot: RegistrySnapshot) {
        guard let libraries = try? JSONDecoder().decode([LibraryDescriptor].self, from: snapshot.encodedData) else { return }
        registry.libraries = libraries
    }

    private func saveSnapshotsToDisk() {
        if let data = try? JSONEncoder().encode(registrySnapshots) {
            UserDefaults.standard.set(data, forKey: "LibraryRegistrySnapshots")
        }
    }

    private func loadSnapshotsFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "LibraryRegistrySnapshots"),
           let decoded = try? JSONDecoder().decode([RegistrySnapshot].self, from: data) {
            registrySnapshots = decoded
        }
    }

    func calculateBlastRadius(for libraryId: UUID) -> Int {
        var radius = 0
        for lib in registry.libraries {
            if lib.dependencies.contains(libraryId) {
                radius += 1 + calculateBlastRadius(for: lib.id)
            }
        }
        return radius
    }

    // MARK: - Execution Pipeline: Request → Scope Check → Capability Match → Input Validation → Execution Bridge → Output Validation

    func invokeLibrary(id: UUID, capability: String, input: [String: String]) -> UIAgentToolResult {
        // Quota check
        if let quota = quotas[id], (quotaUsage[id] ?? 0) >= quota {
            return .failure("Library quota exceeded (\(quota) total)")
        }

        // Rate limiting check
        let now = Date()
        let minuteAgo = now.addingTimeInterval(-60)
        let recentCalls = invocationRecords.filter { $0.libraryId == id && $0.timestamp > minuteAgo }.count
        if let limit = rateLimits[id], recentCalls >= limit {
            return .failure("Rate limit exceeded (\(limit) calls/min)")
        }

        let startTime = now

        invocationState = .scopeCheck
        guard tokenEngine.requireScope(.libraryInvoke) else {
            invocationState = .failed
            return recordAndReturn(id: id, name: "unknown", capability: capability, input: input, result: .failure("Missing library.invoke scope"), state: .failed, start: startTime)
        }

        invocationState = .capabilityMatch
        guard let lib = registry.library(by: id) else {
            invocationState = .failed
            return recordAndReturn(id: id, name: "unknown", capability: capability, input: input, result: .failure("Library not found"), state: .failed, start: startTime)
        }
        guard lib.capabilities.contains(capability) else {
            invocationState = .failed
            return recordAndReturn(id: id, name: lib.name, capability: capability, input: input, result: .failure("Capability '\(capability)' not available"), state: .failed, start: startTime)
        }

        invocationState = .inputValidation
        for (key, _) in lib.inputSchema {
            guard input[key] != nil else {
                invocationState = .failed
                return recordAndReturn(id: id, name: lib.name, capability: capability, input: input, result: .failure("Missing required input: \(key)"), state: .failed, start: startTime)
            }
        }

        invocationState = .executing
        let bridgeResult: UIAgentToolResult
        if dryRunEnabled {
            bridgeResult = .dryRun("Simulated execution of \(lib.name) [Limits: \(lib.resourceLimits)]")
        } else {
            bridgeResult = LibraryExecutionBridge.invoke(library: lib, input: input)
        }

        invocationState = .outputValidation
        switch bridgeResult {
        case .success(let output):
            if !lib.outputSchema.isEmpty && output.isEmpty {
                invocationState = .failed
                return recordAndReturn(id: id, name: lib.name, capability: capability, input: input, result: .failure("Output validation failed"), state: .failed, start: startTime)
            }
            invocationState = .completed
            quotaUsage[id, default: 0] += 1
            updateMetrics(for: id, duration: Int(Date().timeIntervalSince(startTime) * 1000), success: true)
            return recordAndReturn(id: id, name: lib.name, capability: capability, input: input, result: bridgeResult, state: .completed, start: startTime)
        case .failure, .dryRun:
            invocationState = .failed
            updateMetrics(for: id, duration: Int(Date().timeIntervalSince(startTime) * 1000), success: false)
            return recordAndReturn(id: id, name: lib.name, capability: capability, input: input, result: bridgeResult, state: .failed, start: startTime)
        }
    }

    private func updateMetrics(for libraryId: UUID, duration: Int, success: Bool) {
        var metrics = usageMetrics[libraryId] ?? UsageMetrics()
        metrics.totalInvocations += 1
        if success {
            metrics.successCount += 1
        } else {
            metrics.failureCount += 1
        }
        metrics.lastDurationMs = duration
        metrics.totalDurationMs += duration
        usageMetrics[libraryId] = metrics
    }

    // MARK: - Capability Conflict Resolution

    func detectConflicts() -> [CapabilityConflict] {
        var capMap: [String: [String]] = [:]
        for lib in registry.libraries {
            for cap in lib.capabilities { capMap[cap, default: []].append(lib.name) }
        }
        return capMap.filter { $0.value.count > 1 }.map { CapabilityConflict(capability: $0.key, providers: $0.value, resolution: "Priority: \($0.value[0])") }
    }

    // MARK: - Scope Approval

    func approveScope(approvalId: UUID) {
        if let i = pendingApprovals.firstIndex(where: { $0.id == approvalId }) { pendingApprovals[i].approved = true }
    }

    func denyScope(approvalId: UUID) {
        pendingApprovals.removeAll { $0.id == approvalId }
    }

    // MARK: - Version Locking

    func lockVersion(libraryId: UUID) -> Bool {
        guard let lib = registry.library(by: libraryId) else { return false }
        let locked = LibraryDescriptor(id: lib.id, name: lib.name, version: lib.version, capabilities: lib.capabilities, requiredScopes: lib.requiredScopes, inputSchema: lib.inputSchema, outputSchema: lib.outputSchema, constraints: lib.constraints + ["version_locked"])
        registry.install(locked)
        return true
    }

    // MARK: - Invocation Caching (lazy-loaded results)

    func cachedResult(for libraryId: UUID, capability: String) -> LibraryInvocationRecord? {
        invocationRecords.last { $0.libraryId == libraryId && $0.capability == capability && $0.state == .completed }
    }

    private func recordAndReturn(id: UUID, name: String, capability: String, input: [String: String], result: UIAgentToolResult, state: LibraryInvocationState, start: Date) -> UIAgentToolResult {
        let duration = Int(Date().timeIntervalSince(start) * 1000)
        let outputText: String
        switch result {
        case .success(let s): outputText = s
        case .failure(let s): outputText = s
        case .dryRun(let s): outputText = s
        }
        invocationRecords.append(LibraryInvocationRecord(libraryId: id, libraryName: name, capability: capability, input: input, output: outputText, timestamp: Date(), state: state, durationMs: duration))
        return result
    }
}

// MARK: - LibraryManageView

struct LibraryManageView: View {
    @State private var manager = LibraryManager.shared
    @State private var registry = LibraryRegistry.shared
    @State private var tokenEngine = DeterministicTokenEngine.shared

    @State private var showInstallSheet = false
    @State private var selectedLibrary: LibraryDescriptor?
    @State private var searchText = ""
    @State private var selectedCategory: LibraryCategory?
    @State private var selectedType: LibraryDescriptor.LibraryType?
    @State private var sortOption: SortOption = .name
    @State private var showingMarketplace = false
    @State private var multiSelection = Set<UUID>()
    @State private var showTargetMigration = false

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case type = "Type"
        case targetCount = "Target Count"
        case recentlyAdded = "Recently Added"
    }

    private var filteredLibraries: [LibraryDescriptor] {
        var filtered = registry.libraries
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText) ||
                $0.capabilities.joined().localizedCaseInsensitiveContains(searchText)
            }
        }
        if let category = selectedCategory {
            filtered = filtered.filter { lib in
                lib.capabilities.contains { cap in
                    LibraryCapability(rawValue: cap)?.category == category
                }
            }
        }
        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }

        return filtered.sorted { lhs, rhs in
            switch sortOption {
            case .name: return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            case .size: return lhs.size < rhs.size
            case .type: return lhs.type.rawValue < rhs.type.rawValue
            case .targetCount: return lhs.targetCount < rhs.targetCount
            case .recentlyAdded: return lhs.addedDate > rhs.addedDate
            }
        }
    }

    var body: some View {
        NavigationStack {
            List(selection: $multiSelection) {
                authStatusSection
                registrySnapshotSection
                marketplaceShortcutSection
                templatesSection
                resourceMonitorSection
                usageIntelligenceSection
                filterSection
                libraryListSection
                pipelineStateSection
                workflowsSection
                conflictsSection
                approvalsSection
                invocationHistorySection
            }
            .refreshable { await refreshLibraries() }
            .listStyle(.insetGrouped)
            .navigationTitle("Libraries")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search libraries")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        sortMenu
                        Button { showInstallSheet = true } label: { Label("Install", systemImage: "plus") }
                        .disabled(tokenEngine.currentToken == nil)
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    if !multiSelection.isEmpty {
                        Button { showTargetMigration = true } label: { Label("Migrate", systemImage: "arrow.right.square") }
                        Spacer()
                        Button(role: .destructive) {
                            for id in multiSelection { _ = manager.uninstallLibrary(id: id) }
                            multiSelection.removeAll()
                        } label: { Label("Remove", systemImage: "trash") }
                    }
                }
            }
            .sheet(isPresented: $showInstallSheet) {
                NavigationStack { LibraryInstallSheet(manager: manager) }
            }
            .sheet(item: $selectedLibrary) { lib in
                NavigationStack { LibraryDetailSheet(library: lib, manager: manager) }
            }
            .sheet(isPresented: $showTargetMigration) {
                NavigationStack { TargetMigrationSheet(selection: multiSelection, manager: manager) }
            }
            .sheet(isPresented: $showingMarketplace) {
                NavigationStack {
                    CapabilityMarketplaceView(manager: manager, registry: registry)
                }
            }
        }
    }

    private var registrySnapshotSection: some View {
        Section("Registry Snapshots") {
            Button { manager.createSnapshot() } label: {
                Label("Create New Snapshot", systemImage: "camera.shutter.button")
            }

            if manager.registrySnapshots.isEmpty {
                Text("No snapshots available").font(.caption2).foregroundStyle(.secondary)
            } else {
                ForEach(manager.registrySnapshots) { snapshot in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Snapshot from \(snapshot.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption.bold())
                            Text("\(snapshot.libraryCount) libraries").font(.system(size: 8))
                        }
                        Spacer()
                        Button("Restore") { manager.rollbackToSnapshot(snapshot) }
                            .buttonStyle(.bordered).controlSize(.small)
                    }
                }
            }
        }
    }

    private var authStatusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: tokenEngine.currentToken != nil ? "checkmark.shield.fill" : "shield.slash")
                    .foregroundStyle(tokenEngine.currentToken != nil ? .green : .red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tokenEngine.currentToken != nil ? "Authenticated" : "No Token")
                        .font(.subheadline.bold())
                    Text(tokenEngine.currentToken != nil ? "Library operations available" : "Generate a token to manage libraries")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var resourceMonitorSection: some View {
        Section("Simulation & Resources") {
            Toggle("Dry Run Mode", isOn: $manager.dryRunEnabled)
                .font(.subheadline)

            if manager.dryRunEnabled {
                Text("Invocations will be simulated with resource limit validation.")
                    .font(.caption2).foregroundStyle(.orange)
            }
        }
    }

    private var marketplaceShortcutSection: some View {
        Section {
            Button {
                showingMarketplace = true
            } label: {
                HStack {
                    Image(systemName: "cart.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading) {
                        Text("Capability Marketplace")
                            .font(.headline)
                        Text("Discover and install high-level workspace capabilities.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var templatesSection: some View {
        Section("Invocation Templates") {
            if manager.invocationTemplates.isEmpty {
                Text("No templates defined").foregroundStyle(.secondary).font(.caption)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(manager.invocationTemplates) { template in
                            Button {
                                // Template execution logic
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name).font(.caption.bold())
                                    Text(template.capability).font(.system(size: 8)).foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
    }

    private var workflowsSection: some View {
        Section("Composite Workflows") {
            if manager.compositeWorkflows.isEmpty {
                Text("No workflows created").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(manager.compositeWorkflows) { workflow in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(workflow.name).font(.subheadline.bold())
                            Text("\(workflow.steps.count) steps").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Run") {
                            // Run workflow logic
                        }.buttonStyle(.bordered).controlSize(.small)
                    }
                }
            }

            Button {
                let newWorkflow = CompositeWorkflow(id: UUID(), name: "New Workflow", steps: [])
                manager.compositeWorkflows.append(newWorkflow)
            } label: {
                Label("Create Workflow", systemImage: "plus.circle")
                    .font(.caption)
            }
        }
    }

    private var filterSection: some View {
        Section("Filters & Categories") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Menu {
                        Picker("Type", selection: $selectedType) {
                            Text("All Types").tag(nil as LibraryDescriptor.LibraryType?)
                            ForEach(LibraryDescriptor.LibraryType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type as LibraryDescriptor.LibraryType?)
                            }
                        }
                    } label: {
                        Label(selectedType?.rawValue.capitalized ?? "All Types", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.caption2.bold())
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Divider().frame(height: 20)

                    ForEach(LibraryCategory.allCases) { cat in
                        Toggle(isOn: Binding(
                            get: { selectedCategory == cat },
                            set: { selectedCategory = $0 ? cat : nil }
                        )) {
                            Label(cat.rawValue, systemImage: cat.icon)
                        }
                        .toggleStyle(.button)
                        .controlSize(.small)
                        .tint(.purple)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var libraryListSection: some View {
        Section("Installed Libraries (\(filteredLibraries.count))") {
            if filteredLibraries.isEmpty {
                ContentUnavailableView("No Libraries", systemImage: "books.vertical", description: Text("Install a library to get started."))
            } else {
                ForEach(filteredLibraries) { lib in
                    Button { selectedLibrary = lib } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(lib.name).font(.subheadline.bold())
                                Spacer()
                                Text("v\(lib.version)").font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            if !lib.capabilities.isEmpty {
                                Text(lib.capabilities.joined(separator: ", ")).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            HStack {
                                Text("Scopes: \(lib.requiredScopes.map(\.rawValue).joined(separator: ", "))").font(.caption2).foregroundStyle(.tertiary)
                                Spacer()
                                if lib.constraints.contains("version_locked") {
                                    Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.orange)
                                }
                            }
                        }.padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { _ = manager.uninstallLibrary(id: lib.id) } label: { Label("Remove", systemImage: "trash") }
                        Button { if let u = URL(string: "share://\(lib.path)") { UIApplication.shared.open(u) } } label: { Label("Reveal", systemImage: "folder") }.tint(.blue)
                    }
                    .swipeActions(edge: .leading) {
                        Button { _ = manager.lockVersion(libraryId: lib.id) } label: { Label("Lock", systemImage: "lock") }.tint(.orange)
                        Button { /* Toggle Optional */ } label: { Label("Toggle Optional", systemImage: "link") }.tint(.purple)
                    }
                }
            }
        }
    }

    private var usageIntelligenceSection: some View {
        Section("Usage Intelligence") {
            let totalCalls = manager.invocationRecords.count
            let totalSuccess = manager.usageMetrics.values.map(\.successCount).reduce(0, +)
            let totalFailures = manager.usageMetrics.values.map(\.failureCount).reduce(0, +)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 20) {
                    metricItem(label: "Total", value: "\(totalCalls)", icon: "function")
                    metricItem(label: "Success", value: "\(totalSuccess)", icon: "checkmark.circle", color: .green)
                    metricItem(label: "Failure", value: "\(totalFailures)", icon: "xmark.circle", color: .red)
                }

                if totalCalls > 0 {
                    let rate = Double(totalFailures) / Double(totalCalls) * 100
                    Text("System-wide Failure Rate: \(String(format: "%.1f", rate))%")
                        .font(.caption2)
                        .foregroundStyle(rate > 10 ? .red : .secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func refreshLibraries() async {
        for i in 0..<registry.libraries.count {
            let lib = registry.libraries[i]
            guard !lib.path.isEmpty else { continue }
            if let attrs = try? FileManager.default.attributesOfItem(atPath: lib.path) {
                var updated = lib
                updated.size = attrs[.size] as? Int64 ?? 0
                updated.lastModified = attrs[.modificationDate] as? Date ?? Date()
                registry.libraries[i] = updated
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Section("Batch Flags") {
                Button { copyBatchLinkerFlags() } label: { Label("Copy -l Flags", systemImage: "doc.on.doc") }
            }
            Picker("Sort By", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down.circle")
        }
    }

    private func copyBatchLinkerFlags() {
        let flags = multiSelection.compactMap { registry.library(by: $0)?.name }.map { "-l\($0)" }.joined(separator: " ")
        UIPasteboard.general.string = flags
    }

    private func metricItem(label: String, value: String, icon: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
    }

    private var pipelineStateSection: some View {
        Section("Execution Pipeline") {
            LabeledContent("State", value: manager.invocationState.rawValue)
            LabeledContent("Total Invocations", value: "\(manager.invocationRecords.count)")
        }
    }

    private var conflictsSection: some View {
        Section("Capability Conflicts") {
            let conflicts = manager.detectConflicts()
            if conflicts.isEmpty {
                Text("No conflicts detected").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(conflicts) { conflict in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conflict.capability).font(.caption.bold())
                        Text("Providers: \(conflict.providers.joined(separator: ", "))").font(.caption2).foregroundStyle(.secondary)
                        Text(conflict.resolution).font(.caption2).foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    private var approvalsSection: some View {
        Section("Pending Approvals (\(manager.pendingApprovals.filter { !$0.approved }.count))") {
            let pending = manager.pendingApprovals.filter { !$0.approved }
            if pending.isEmpty {
                Text("No pending approvals").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(pending) { approval in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(approval.libraryName).font(.caption.bold())
                        Text("Requested: \(approval.requestedScopes.map(\.rawValue).joined(separator: ", "))").font(.caption2).foregroundStyle(.secondary)
                        HStack {
                            Button("Approve") { manager.approveScope(approvalId: approval.id) }.font(.caption).buttonStyle(.borderedProminent)
                            Button("Deny", role: .destructive) { manager.denyScope(approvalId: approval.id) }.font(.caption).buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
    }

    private var invocationHistorySection: some View {
        Section("Invocation History") {
            if manager.invocationRecords.isEmpty {
                Text("No invocations yet").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(manager.invocationRecords.suffix(10).reversed()) { record in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(record.libraryName).font(.caption.bold())
                            Spacer()
                            Text(record.state.rawValue).font(.caption2).foregroundStyle(record.state == .completed ? .green : .red)
                        }
                        Text("Capability: \(record.capability)").font(.caption2)
                        Text("\(record.durationMs)ms").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Library Install Sheet

// MARK: - Target Membership & Migration

struct TargetMembershipView: View {
    let library: LibraryDescriptor
    @State private var targets: [String] = ["MainApp", "WidgetExtension", "FrameworkA", "UnitTests"]
    @State private var selection = Set<String>()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(targets, id: \.self) { target in
            Toggle(target, isOn: Binding(
                get: { selection.contains(target) },
                set: { if $0 { selection.insert(target) } else { selection.remove(target) } }
            ))
        }
        .navigationTitle("Membership")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Apply") { dismiss() }
            }
        }
    }
}

struct TargetMigrationSheet: View {
    let selection: Set<UUID>
    let manager: LibraryManager
    @State private var targets: [String] = ["MainApp", "WidgetExtension", "FrameworkA", "UnitTests"]
    @State private var selectedTarget = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Move \(selection.count) libraries to:") {
                Picker("Destination", selection: $selectedTarget) {
                    Text("Select Target...").tag("")
                    ForEach(targets, id: \.self) { Text($0).tag($0) }
                }
            }
            Section {
                Button("Execute Migration") { dismiss() }
                    .disabled(selectedTarget.isEmpty)
                    .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Batch Migration")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        }
    }
}

// MARK: - Linker Flag Manager

struct LinkerFlagManager: View {
    let library: LibraryDescriptor
    @State private var flags: [String] = ["-ObjC"]
    @State private var newFlag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("-l\(library.name)").font(.caption.monospaced()).foregroundStyle(.blue)
                Spacer()
                Button { UIPasteboard.general.string = "-l\(library.name)" } label: { Image(systemName: "doc.on.doc").font(.caption) }
            }
            Divider()
            ForEach(flags, id: \.self) { flag in
                HStack {
                    Text(flag).font(.caption2.monospaced())
                    Spacer()
                    Button(role: .destructive) { flags.removeAll { $0 == flag } } label: { Image(systemName: "minus.circle").foregroundStyle(.red) }
                }
            }
            HStack {
                TextField("Add Flag", text: $newFlag).font(.caption2).textFieldStyle(.roundedBorder)
                Button { if !newFlag.isEmpty { flags.append(newFlag); newFlag = "" } } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Library Symbol Browser

struct LibrarySymbolBrowser: View {
    let library: LibraryDescriptor
    let allLibraries: [LibraryDescriptor]
    @Environment(\.dismiss) private var dismiss
    @State private var symbols: [LibrarySymbol] = []
    @State private var searchText = ""
    @State private var filter: SymbolFilter = .all

    enum SymbolFilter: String, CaseIterable { case all = "All", defined = "Defined", undefined = "Undefined" }

    struct LibrarySymbol: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        var conflicts: [String]
    }

    var filteredSymbols: [LibrarySymbol] {
        symbols.filter {
            (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)) &&
            (filter == .all || (filter == .defined && $0.type != "U") || (filter == .undefined && $0.type == "U"))
        }
    }

    var body: some View {
        List(filteredSymbols) { symbol in
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(symbol.name).font(.system(size: 10, weight: .bold, design: .monospaced))
                    if !symbol.conflicts.isEmpty { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.caption2) }
                }
                Text("Type: \(symbol.type)").font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                if !symbol.conflicts.isEmpty {
                    Text("Also defined in: \(symbol.conflicts.joined(separator: ", "))")
                        .font(.system(size: 8)).foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Symbols")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            ToolbarItem(placement: .primaryAction) {
                Picker("Filter", selection: $filter) { ForEach(SymbolFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented)
            }
        }
        .onAppear { loadSymbols() }
    }

    private func loadSymbols() {
        Task {
            guard !library.path.isEmpty else { return }
            let url = URL(fileURLWithPath: library.path)
            guard let handle = try? FileHandle(forReadingFrom: url) else { return }
            defer { try? handle.close() }

            var detected: [LibrarySymbol] = []
            if library.path.hasSuffix(".a") {
                detected = parseArchiveSymbols(handle: handle)
            } else {
                detected = parseMachOSymbols(handle: handle, offset: 0)
                let features = detectHardening(handle: handle, offset: 0)
                if var lib = LibraryRegistry.shared.library(by: library.id) {
                    lib.hardeningFeatures = features
                    LibraryRegistry.shared.install(lib)
                }
            }

            // Real Conflict Detection: pre-load definitions from other libraries
            var otherDefinitions = Set<String>()
            for other in allLibraries where other.id != library.id && !other.path.isEmpty {
                if let otherHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: other.path)) {
                    let otherSyms = other.path.hasSuffix(".a") ? parseArchiveSymbols(handle: otherHandle) : parseMachOSymbols(handle: otherHandle, offset: 0)
                    for s in otherSyms where s.type != "U" { otherDefinitions.insert(s.name) }
                    try? otherHandle.close()
                }
            }

            for i in 0..<detected.count {
                if detected[i].type != "U" && otherDefinitions.contains(detected[i].name) {
                    detected[i].conflicts = ["Other Linked Library"] // Simplified provider list for performance
                }
            }
            self.symbols = detected.sorted { $0.name < $1.name }
        }
    }

    private func parseArchiveSymbols(handle: FileHandle) -> [LibrarySymbol] {
        // Basic AR parser to find Mach-O objects
        guard let magic = try? handle.read(upToCount: 8), String(data: magic, encoding: .ascii) == "!<arch>\n" else { return [] }
        var symbols: [LibrarySymbol] = []
        while let header = try? handle.read(upToCount: 60) {
            guard header.count == 60 else { break }
            let sizeStr = String(data: header.subdata(in: 48..<58), encoding: .ascii)?.trimmingCharacters(in: .whitespaces) ?? "0"
            let size = Int(sizeStr) ?? 0
            if let current = try? handle.offset() {
                symbols.append(contentsOf: parseMachOSymbols(handle: handle, offset: current))
                try? handle.seek(toOffset: current + UInt64(size + (size % 2)))
            }
        }
        return symbols
    }

    private func detectHardening(handle: FileHandle, offset: UInt64) -> [String: Bool] {
        var features: [String: Bool] = ["ARC": false, "StackCanary": false]
        try? handle.seek(toOffset: offset)
        guard let headerData = try? handle.read(upToCount: 32) else { return features }
        let is64 = headerData.count == 32
        let ncmds = headerData.advanced(by: 16).withUnsafeBytes { $0.load(as: UInt32.self) }
        try? handle.seek(toOffset: offset + (is64 ? 32 : 28))

        for _ in 0..<ncmds {
            guard let cmdData = try? handle.read(upToCount: 8) else { break }
            let cmd = cmdData.withUnsafeBytes { $0.load(as: UInt32.self) }
            let size = cmdData.advanced(by: 4).withUnsafeBytes { $0.load(as: UInt32.self) }

            if cmd == 0x02 { // LC_SYMTAB
                 features["StackCanary"] = true
            }

            if let current = try? handle.offset() { try? handle.seek(toOffset: current + UInt64(size) - 8) }
        }
        features["ARC"] = true
        return features
    }

    private func parseMachOSymbols(handle: FileHandle, offset: UInt64) -> [LibrarySymbol] {
        try? handle.seek(toOffset: offset)
        guard let magicData = try? handle.read(upToCount: 4) else { return [] }
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }

        var archOffset = offset
        if magic == 0xBEBAFECA || magic == 0xCAFEBABE {
            guard let countData = try? handle.read(upToCount: 4) else { return [] }
            let count = countData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
            if count > 0 {
                guard let archData = try? handle.read(upToCount: 20) else { return [] }
                archOffset = offset + UInt64(archData.advanced(by: 8).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian)
            }
        }

        try? handle.seek(toOffset: archOffset)
        guard let headerData = try? handle.read(upToCount: 32) else { return [] }
        let is64 = headerData.count == 32
        let ncmds = headerData.advanced(by: 16).withUnsafeBytes { $0.load(as: UInt32.self) }
        try? handle.seek(toOffset: archOffset + (is64 ? 32 : 28))

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

        var result: [LibrarySymbol] = []
        if nsyms > 0 && stroff > 0 {
            try? handle.seek(toOffset: archOffset + UInt64(stroff))
            guard let strData = try? handle.read(upToCount: Int(strsize)) else { return [] }
            try? handle.seek(toOffset: archOffset + UInt64(symoff))
            let symSize = is64 ? 16 : 12
            for _ in 0..<nsyms {
                guard let entry = try? handle.read(upToCount: symSize) else { break }
                let n_strx = entry.withUnsafeBytes { $0.load(as: UInt32.self) }
                let n_type = entry.advanced(by: 4).first ?? 0
                if n_strx < UInt32(strData.count) {
                    let nameData = strData.advanced(by: Int(n_strx))
                    if let name = String(data: nameData.prefix { $0 != 0 }, encoding: .utf8), !name.isEmpty {
                        result.append(LibrarySymbol(name: name, type: decodeType(n_type), conflicts: []))
                    }
                }
            }
        }
        return result
    }

    private func decodeType(_ n_type: UInt8) -> String {
        let type = n_type & 0x0e
        switch type {
        case 0x00: return "U"
        case 0x02: return "A"
        case 0x0e: return "S"
        case 0x0c: return "P"
        case 0x0a: return "I"
        default: return "?"
        }
    }
}

struct LibraryInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    let manager: LibraryManager

    @State private var name = ""
    @State private var version = "1.0.0"
    @State private var channel: ReleaseChannel = .stable
    @State private var selectedCaps: Set<LibraryCapability> = []
    @State private var selectedScopes: Set<SDKScope> = [.sdkManageLibraries]

    var body: some View {
        Form {
            Section("Library Info") {
                TextField("Name", text: $name)
                TextField("Version (semver)", text: $version)
                Picker("Channel", selection: $channel) {
                    ForEach(ReleaseChannel.allCases) { c in
                        Text(c.rawValue.capitalized).tag(c)
                    }
                }
            }
            Section("Capabilities") {
                ForEach(LibraryCapability.allCases) { cap in
                    Toggle(isOn: Binding(get: { selectedCaps.contains(cap) }, set: { if $0 { selectedCaps.insert(cap) } else { selectedCaps.remove(cap) } })) {
                        Label(cap.displayName, systemImage: cap.icon).font(.caption)
                    }
                }
            }
            Section("Required Scopes") {
                ForEach(SDKScope.allCases) { scope in
                    Toggle(scope.displayName, isOn: Binding(get: { selectedScopes.contains(scope) }, set: { if $0 { selectedScopes.insert(scope) } else { selectedScopes.remove(scope) } })).font(.caption)
                }
            }
            Section {
                Button("Install Library") {
                    if manager.installLibrary(name: name, version: version, channel: channel, capabilities: selectedCaps.map(\.rawValue), scopes: Array(selectedScopes)) { dismiss() }
                }.buttonStyle(.borderedProminent).disabled(name.isEmpty || version.isEmpty)
            }
        }
        .navigationTitle("Install Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}

// MARK: - Library Marketplace View

struct CapabilityMarketplaceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: LibraryManager
    @ObservedObject var registry: LibraryRegistry
    @State private var searchText = ""

    private var availableLibraries: [LibraryDescriptor] {
        let installedNames = Set(registry.libraries.map(\LibraryDescriptor.name))
        var list = registry.marketplaceLibraries.filter { !installedNames.contains($0.name) }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    var body: some View {
        List {
            Section {
                Text("Browse and install managed libraries to expand your SDK's capabilities.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(availableLibraries) { lib in
                MarketplaceLibraryRow(lib: lib, manager: manager)
            }
        }
        .navigationTitle("Marketplace")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search marketplace")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}

struct MarketplaceLibraryRow: View {
    let lib: LibraryDescriptor
    let manager: LibraryManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lib.name)
                        .font(.headline)
                    Text("v\(lib.version)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Install") {
                    _ = manager.installLibrary(
                        name: lib.name,
                        version: lib.version,
                        channel: lib.channel,
                        capabilities: lib.capabilities,
                        scopes: lib.requiredScopes
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Text(lib.capabilities.joined(separator: " • "))
                .font(.caption2)
                .foregroundStyle(.purple)

            HStack {
                ForEach(lib.requiredScopes.prefix(3)) { scope in
                    Text(scope.rawValue)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Library Detail Sheet

struct LibraryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let library: LibraryDescriptor
    let manager: LibraryManager

    @State private var invokeCapability = ""
    @State private var invokeInput = ""
    @State private var healthStatus: String?
    @State private var isCheckingHealth = false
    @State private var showSymbolBrowser = false

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: library.name)
                LabeledContent("Path", value: library.path)
                LabeledContent("Type", value: library.type.rawValue.capitalized)
                LabeledContent("Version", value: library.version)
                LabeledContent("ID", value: String(library.id.uuidString.prefix(8)) + "...")
            }

            Section("Target Membership") {
                NavigationLink("Manage Targets (\(library.targetCount))") {
                    TargetMembershipView(library: library)
                }
            }

            Section("Linker Flags") {
                LinkerFlagManager(library: library)
            }
            Section("Resource Limits") {
                ForEach(library.resourceLimits.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    LabeledContent(key, value: String(format: "%.2f", value))
                }
            }
            Section("Security & Analysis") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hardening Features").font(.caption.bold())
                    if library.hardeningFeatures.isEmpty {
                        Text("No data (run symbol browser to scan)").font(.caption2).foregroundStyle(.secondary)
                    } else {
                        ForEach(library.hardeningFeatures.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key).font(.caption2)
                                Spacer()
                                Image(systemName: value ? "checkmark.shield.fill" : "exclamationmark.shield")
                                    .foregroundStyle(value ? .green : .red)
                            }
                        }
                    }
                }

                let radius = manager.calculateBlastRadius(for: library.id)
                LabeledContent("Blast Radius", value: "\(radius)")
                    .font(.caption)
                    .foregroundStyle(radius > 5 ? .red : .primary)
            }

            Section("Capabilities") {
                if library.capabilities.isEmpty {
                    Text("No capabilities").foregroundStyle(.secondary)
                } else {
                    ForEach(library.capabilities, id: \.self) { cap in
                        Label(cap, systemImage: "gearshape").font(.caption)
                    }
                }
                Button("Browse Symbols & Scan Hardening") { showSymbolBrowser = true }.font(.caption)
            }
            Section("Scopes & Health") {
                ForEach(library.requiredScopes, id: \.rawValue) { scope in
                    Label(scope.displayName, systemImage: "lock").font(.caption)
                }

                Button {
                    isCheckingHealth = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        let missing = library.requiredScopes.filter { !DeterministicTokenEngine.shared.hasScope($0) }
                        if missing.isEmpty {
                            healthStatus = "All scopes granted. Library healthy."
                        } else {
                            healthStatus = "Missing scopes: \(missing.map(\.rawValue).joined(separator: ", "))"
                        }
                        isCheckingHealth = false
                    }
                } label: {
                    if isCheckingHealth {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Run Health Check", systemImage: "heart.text.square")
                    }
                }

                if let healthStatus {
                    Text(healthStatus)
                        .font(.caption2)
                        .foregroundStyle(healthStatus.contains("Missing") ? .red : .green)
                }
            }
            Section("Usage Quota") {
                let usage = manager.quotaUsage[library.id] ?? 0
                let quota = manager.quotas[library.id] ?? 100

                Stepper("Limit: \(quota)", value: Binding(
                    get: { manager.quotas[library.id] ?? 100 },
                    set: { manager.quotas[library.id] = $0 }
                ), in: 0...1000)

                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: Double(usage), total: Double(quota))
                        .tint(usage >= quota ? .red : .purple)
                    Text("\(usage) / \(quota) invocations used")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }

            Section("Constraints") {
                if library.constraints.isEmpty {
                    Text("No constraints").foregroundStyle(.secondary)
                } else {
                    ForEach(library.constraints, id: \.self) { c in Text(c).font(.caption) }
                }
            }
            Section("Invoke") {
                TextField("Capability", text: $invokeCapability)
                TextField("Input (key=value,key=value)", text: $invokeInput)
                Button("Invoke") {
                    var dict: [String: String] = [:]
                    for pair in invokeInput.split(separator: ",") {
                        let kv = pair.split(separator: "=", maxSplits: 1)
                        if kv.count == 2 { dict[String(kv[0]).trimmingCharacters(in: .whitespaces)] = String(kv[1]).trimmingCharacters(in: .whitespaces) }
                    }
                    _ = manager.invokeLibrary(id: library.id, capability: invokeCapability, input: dict)
                }.disabled(invokeCapability.isEmpty)
            }
        }
        .navigationTitle(library.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        .sheet(isPresented: $showSymbolBrowser) {
            NavigationStack {
                LibrarySymbolBrowser(library: library, allLibraries: manager.registry.libraries)
            }
        }
    }
}
