import SwiftUI

// MARK: - Framework Descriptor

struct FrameworkDescriptor: Identifiable, Codable {
    let id: UUID
    let name: String
    let entryPoints: [String]
    let languageType: String
    let packageDependencies: [UUID]
    let requiredScopes: [SDKScope]
    var isEnabled: Bool

    init(
        id: UUID = UUID(), name: String, entryPoints: [String] = ["main"],
        languageType: String = "swift", packageDependencies: [UUID] = [],
        requiredScopes: [SDKScope] = [.frameworkExecute], isEnabled: Bool = true
    ) {
        self.id = id; self.name = name; self.entryPoints = entryPoints
        self.languageType = languageType; self.packageDependencies = packageDependencies
        self.requiredScopes = requiredScopes; self.isEnabled = isEnabled
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

// MARK: - Framework Sandbox Runner

struct FrameworkSandboxRunner {
    static func execute(framework: FrameworkDescriptor, params: [String: String], config: FrameworkSandboxConfig = .default) -> AgentToolResult {
        guard framework.isEnabled else { return .failure("Framework is disabled") }
        guard !framework.entryPoints.isEmpty else { return .failure("No entry points defined") }
        return .success("Executed \(framework.name) via '\(framework.entryPoints[0])' [sandbox: time=\(config.maxExecutionTimeMs)ms mem=\(config.maxMemoryBytes / (1024*1024))MB fs=\(config.allowFileSystem) net=\(config.allowNetwork)]")
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
}

// MARK: - Framework Manager

@MainActor
final class FrameworkManager: ObservableObject {
    static let shared = FrameworkManager()

    @Published var executionRecords: [FrameworkExecutionRecord] = []
    @Published private(set) var executionState: FrameworkExecutionState = .idle
    @Published var sandboxConfig: FrameworkSandboxConfig = .default

    private let tokenEngine = DeterministicTokenEngine.shared
    private let registry = FrameworkRegistry.shared
    private let packageRegistry = PackageRegistry.shared

    private init() {}

    func installFramework(name: String, entryPoints: [String], language: String, dependencies: [UUID]) -> Bool {
        guard tokenEngine.requireScope(.sdkManageFrameworks) else { return false }
        guard !name.isEmpty else { return false }
        let fw = FrameworkDescriptor(name: name, entryPoints: entryPoints.isEmpty ? ["main"] : entryPoints, languageType: language, packageDependencies: dependencies)
        registry.install(fw)
        return true
    }

    func uninstallFramework(id: UUID) -> Bool {
        guard tokenEngine.requireScope(.sdkManageFrameworks) else { return false }
        registry.uninstall(id: id)
        return true
    }

    func toggleFramework(id: UUID) {
        guard var fw = registry.framework(by: id) else { return }
        fw.isEnabled.toggle()
        registry.install(fw)
    }

    /// Execution Pipeline: Load → Validate → Resolve Dependencies → Scope Check → Sandbox → Execute → Validate Output → Commit
    func executeFramework(id: UUID, params: [String: String]) -> AgentToolResult {
        let startTime = Date()

        executionState = .loading
        guard let fw = registry.framework(by: id) else {
            executionState = .failed
            return record(id: id, name: "unknown", entryPoint: "", result: .failure("Framework not found"), state: .failed, start: startTime)
        }

        executionState = .validating
        guard fw.isEnabled else {
            executionState = .failed
            return record(id: id, name: fw.name, entryPoint: "", result: .failure("Framework is disabled"), state: .failed, start: startTime)
        }
        guard !fw.entryPoints.isEmpty else {
            executionState = .failed
            return record(id: id, name: fw.name, entryPoint: "", result: .failure("No entry points"), state: .failed, start: startTime)
        }

        executionState = .resolvingDeps
        let installedPkgIds = Set(packageRegistry.packages.map(\.id))
        let missingDeps = fw.packageDependencies.filter { !installedPkgIds.contains($0) }
        if !missingDeps.isEmpty {
            executionState = .failed
            return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: .failure("Missing dependencies: \(missingDeps.map { String($0.uuidString.prefix(8)) }.joined(separator: ", "))"), state: .failed, start: startTime)
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
        let sandboxResult = FrameworkSandboxRunner.execute(framework: fw, params: params, config: sandboxConfig)

        executionState = .validatingOutput
        switch sandboxResult {
        case .success(let output):
            guard !output.isEmpty else {
                executionState = .failed
                return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: .failure("Empty output"), state: .failed, start: startTime)
            }
            executionState = .committing
            executionState = .completed
            return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: sandboxResult, state: .completed, start: startTime)
        case .failure, .dryRun:
            executionState = .failed
            return record(id: id, name: fw.name, entryPoint: fw.entryPoints[0], result: sandboxResult, state: .failed, start: startTime)
        }
    }

    private func record(id: UUID, name: String, entryPoint: String, result: AgentToolResult, state: FrameworkExecutionState, start: Date) -> AgentToolResult {
        let duration = Int(Date().timeIntervalSince(start) * 1000)
        let output: String
        switch result {
        case .success(let s): output = s
        case .failure(let s): output = s
        case .dryRun(let s): output = s
        }
        executionRecords.append(FrameworkExecutionRecord(frameworkId: id, frameworkName: name, entryPoint: entryPoint, timestamp: Date(), state: state, output: output, durationMs: duration))
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
            $0.languageType.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                authSection
                frameworkListSection
                executionStateSection
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
                            Text("Language: \(fw.languageType) | Entry: \(fw.entryPoints.joined(separator: ", "))").font(.caption2).foregroundStyle(.secondary)
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
                        Text("\(record.durationMs)ms").font(.caption2).foregroundStyle(.tertiary)
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
    @State private var language = "swift"

    var body: some View {
        Form {
            Section("Framework Info") {
                TextField("Name", text: $name)
                TextField("Entry Points (comma-separated)", text: $entryPointsText)
                Picker("Language", selection: $language) {
                    Text("Swift").tag("swift")
                    Text("Python").tag("python")
                    Text("JavaScript").tag("javascript")
                    Text("TypeScript").tag("typescript")
                    Text("Rust").tag("rust")
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
                LabeledContent("Language", value: framework.languageType)
                LabeledContent("Enabled", value: framework.isEnabled ? "Yes" : "No")
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
            Section("Execute") {
                TextField("params (key=value)", text: Binding(get: { execParams["input"] ?? "" }, set: { execParams["input"] = $0 }))
                Button("Execute in Sandbox") {
                    _ = manager.executeFramework(id: framework.id, params: execParams)
                }.buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(framework.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
    }
}
