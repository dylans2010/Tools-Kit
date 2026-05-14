import SwiftUI

// MARK: - Library Descriptor

struct LibraryDescriptor: Identifiable, Codable {
    let id: UUID
    let name: String
    let version: String
    let capabilities: [String]
    let requiredScopes: [SDKScope]
    let inputSchema: [String: String]
    let outputSchema: [String: String]
    let constraints: [String]

    init(
        id: UUID = UUID(), name: String, version: String,
        capabilities: [String] = [], requiredScopes: [SDKScope] = [],
        inputSchema: [String: String] = [:], outputSchema: [String: String] = [:],
        constraints: [String] = []
    ) {
        self.id = id; self.name = name; self.version = version
        self.capabilities = capabilities; self.requiredScopes = requiredScopes
        self.inputSchema = inputSchema; self.outputSchema = outputSchema
        self.constraints = constraints
    }
}

// MARK: - Library Capability

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
    static func invoke(library: LibraryDescriptor, input: [String: String]) -> AgentToolResult {
        guard !library.capabilities.isEmpty else {
            return .failure("Library has no capabilities")
        }
        return .success("Invoked \(library.name) with \(input.count) parameters via SDK bridge")
    }
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

    private init() {}

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
    @Published var pendingApprovals: [LibraryScopeApproval] = []
    @Published private(set) var invocationState: LibraryInvocationState = .idle

    private let tokenEngine = DeterministicTokenEngine.shared
    private let registry = LibraryRegistry.shared

    struct LibraryScopeApproval: Identifiable {
        let id = UUID()
        let libraryId: UUID
        let libraryName: String
        let requestedScopes: [SDKScope]
        let timestamp: Date
        var approved: Bool = false
    }

    private init() {}

    // MARK: - Install / Uninstall

    func installLibrary(name: String, version: String, capabilities: [String], scopes: [SDKScope]) -> Bool {
        guard tokenEngine.requireScope(.sdkManageLibraries) else { return false }
        guard !name.isEmpty, !version.isEmpty else { return false }

        let lib = LibraryDescriptor(name: name, version: version, capabilities: capabilities, requiredScopes: scopes)
        registry.install(lib)
        pendingApprovals.append(LibraryScopeApproval(libraryId: lib.id, libraryName: name, requestedScopes: scopes, timestamp: Date()))
        return true
    }

    func uninstallLibrary(id: UUID) -> Bool {
        guard tokenEngine.requireScope(.sdkManageLibraries) else { return false }
        registry.uninstall(id: id)
        return true
    }

    // MARK: - Execution Pipeline: Request → Scope Check → Capability Match → Input Validation → Execution Bridge → Output Validation

    func invokeLibrary(id: UUID, capability: String, input: [String: String]) -> AgentToolResult {
        let startTime = Date()

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
        let bridgeResult = LibraryExecutionBridge.invoke(library: lib, input: input)

        invocationState = .outputValidation
        switch bridgeResult {
        case .success(let output):
            if !lib.outputSchema.isEmpty && output.isEmpty {
                invocationState = .failed
                return recordAndReturn(id: id, name: lib.name, capability: capability, input: input, result: .failure("Output validation failed"), state: .failed, start: startTime)
            }
            invocationState = .completed
            return recordAndReturn(id: id, name: lib.name, capability: capability, input: input, result: bridgeResult, state: .completed, start: startTime)
        case .failure, .dryRun:
            invocationState = .failed
            return recordAndReturn(id: id, name: lib.name, capability: capability, input: input, result: bridgeResult, state: .failed, start: startTime)
        }
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

    private func recordAndReturn(id: UUID, name: String, capability: String, input: [String: String], result: AgentToolResult, state: LibraryInvocationState, start: Date) -> AgentToolResult {
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
    @StateObject private var manager = LibraryManager.shared
    @StateObject private var registry = LibraryRegistry.shared
    @StateObject private var tokenEngine = DeterministicTokenEngine.shared

    @State private var showInstallSheet = false
    @State private var selectedLibrary: LibraryDescriptor?
    @State private var searchText = ""

    private var filteredLibraries: [LibraryDescriptor] {
        if searchText.isEmpty { return registry.libraries }
        return registry.libraries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.capabilities.joined().localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                authStatusSection
                libraryListSection
                pipelineStateSection
                conflictsSection
                approvalsSection
                invocationHistorySection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Libraries")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search libraries")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showInstallSheet = true } label: { Label("Install", systemImage: "plus") }
                    .disabled(tokenEngine.currentToken == nil)
                }
            }
            .sheet(isPresented: $showInstallSheet) {
                NavigationStack { LibraryInstallSheet(manager: manager) }
            }
            .sheet(item: $selectedLibrary) { lib in
                NavigationStack { LibraryDetailSheet(library: lib, manager: manager) }
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
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { _ = manager.uninstallLibrary(id: lib.id) } label: { Label("Remove", systemImage: "trash") }
                    }
                    .swipeActions(edge: .leading) {
                        Button { _ = manager.lockVersion(libraryId: lib.id) } label: { Label("Lock", systemImage: "lock") }.tint(.orange)
                    }
                }
            }
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

struct LibraryInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    let manager: LibraryManager

    @State private var name = ""
    @State private var version = "1.0.0"
    @State private var selectedCaps: Set<LibraryCapability> = []
    @State private var selectedScopes: Set<SDKScope> = [.sdkManageLibraries]

    var body: some View {
        Form {
            Section("Library Info") {
                TextField("Name", text: $name)
                TextField("Version (semver)", text: $version)
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
                    if manager.installLibrary(name: name, version: version, capabilities: selectedCaps.map(\.rawValue), scopes: Array(selectedScopes)) { dismiss() }
                }.buttonStyle(.borderedProminent).disabled(name.isEmpty || version.isEmpty)
            }
        }
        .navigationTitle("Install Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}

// MARK: - Library Detail Sheet

struct LibraryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let library: LibraryDescriptor
    let manager: LibraryManager

    @State private var invokeCapability = ""
    @State private var invokeInput = ""

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: library.name)
                LabeledContent("Version", value: library.version)
                LabeledContent("ID", value: String(library.id.uuidString.prefix(8)) + "...")
            }
            Section("Capabilities") {
                if library.capabilities.isEmpty {
                    Text("No capabilities").foregroundStyle(.secondary)
                } else {
                    ForEach(library.capabilities, id: \.self) { cap in
                        Label(cap, systemImage: "gearshape").font(.caption)
                    }
                }
            }
            Section("Scopes") {
                ForEach(library.requiredScopes, id: \.rawValue) { scope in
                    Label(scope.displayName, systemImage: "lock").font(.caption)
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
    }
}
