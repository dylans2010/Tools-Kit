import SwiftUI

// MARK: - Agent Tool System

enum AgentToolName: String, CaseIterable, Identifiable {
    case installPackage
    case resolveDependencies
    case installLibrary
    case invokeLibrary
    case attachFramework
    case executeFramework
    case createNote
    case sendEmail
    case createSlides
    case updateTask
    case managePackages

    var id: String { rawValue }

    var requiredScope: SDKScope {
        switch self {
        case .installPackage, .resolveDependencies, .managePackages: return .sdkManagePackages
        case .installLibrary: return .sdkManageLibraries
        case .invokeLibrary: return .libraryInvoke
        case .attachFramework: return .sdkManageFrameworks
        case .executeFramework: return .frameworkExecute
        case .createNote: return .notes
        case .sendEmail: return .emails
        case .createSlides: return .slides
        case .updateTask: return .tasks
        }
    }

    var displayName: String {
        switch self {
        case .installPackage: return "Install Package"
        case .resolveDependencies: return "Resolve Dependencies"
        case .installLibrary: return "Install Library"
        case .invokeLibrary: return "Invoke Library"
        case .attachFramework: return "Attach Framework"
        case .executeFramework: return "Execute Framework"
        case .createNote: return "Create Note"
        case .sendEmail: return "Send Email"
        case .createSlides: return "Create Slides"
        case .updateTask: return "Update Task"
        case .managePackages: return "Manage Packages"
        }
    }
}

struct AgentToolInvocation: Identifiable {
    let id = UUID()
    let tool: AgentToolName
    let parameters: [String: String]
    let timestamp: Date
    var result: UIAgentToolResult?
}

// MARK: - Agent Intent & Plan

enum AgentIntent: String, Codable {
    case install, resolve, execute, inspect, takeover, rollback
}

struct PersonaAgentPlanStep: Identifiable {
    let id = UUID()
    let intent: AgentIntent
    let description: String
    let tool: AgentToolName?
    let parameters: [String: String]?
    let requiredScopes: Set<SDKScope>
    var status: StepStatus = .pending

    enum StepStatus: String {
        case pending, executing, completed, failed, rolledBack
    }

    init(intent: AgentIntent, description: String, tool: AgentToolName? = nil, parameters: [String: String]? = nil, requiredScopes: Set<SDKScope>) {
        self.intent = intent
        self.description = description
        self.tool = tool
        self.parameters = parameters
        self.requiredScopes = requiredScopes
    }
}

// MARK: - Agent Execution State

enum AgentExecutionState: String {
    case idle, planning, executing, awaitingApproval, takenOver, completed, failed, rolledBack
}

enum AgentExecutionProfile: String, CaseIterable, Codable {
    case precise, balanced, aggressive

    var stepMultiplier: Int {
        switch self {
        case .precise: return 2
        case .balanced: return 1
        case .aggressive: return 0 // skip some checks
        }
    }
}

// MARK: - PersonaAgentFramework Core Engine

@MainActor
final class PersonaAgentFramework: ObservableObject {
    static let shared = PersonaAgentFramework()

    @Published private(set) var executionState: AgentExecutionState = .idle
    @Published private(set) var currentPlan: [PersonaAgentPlanStep] = []
    @Published private(set) var invocationLog: [AgentToolInvocation] = []
    @Published private(set) var auditLog: [AgentAuditEntry] = []
    @Published var takeoverActive: Bool = false
    @Published var takeoverScopes: Set<SDKScope> = []
    @Published var currentProfile: AgentExecutionProfile = .balanced

    private let tokenEngine = DeterministicTokenEngine.shared

    struct AgentAuditEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let action: String
        let detail: String
        let outcome: String
    }

    private init() {}

    // MARK: - Intent Parsing

    func parseIntent(from input: String) -> AgentIntent {
        let lower = input.lowercased()
        if lower.contains("install") { return .install }
        if lower.contains("resolve") || lower.contains("dependency") { return .resolve }
        if lower.contains("execute") || lower.contains("run") { return .execute }
        if lower.contains("inspect") || lower.contains("check") { return .inspect }
        if lower.contains("takeover") || lower.contains("take over") { return .takeover }
        if lower.contains("rollback") || lower.contains("revert") { return .rollback }
        return .inspect
    }

    // MARK: - Multi-Step Planning

    func buildPlan(for intent: AgentIntent, target: String) -> [PersonaAgentPlanStep] {
        executionState = .planning
        var steps: [PersonaAgentPlanStep] = []

        // Pre-validation before planning
        if target.isEmpty {
            audit("Planning Failed", detail: "Empty target", outcome: "aborted")
            executionState = .failed
            return []
        }

        // Project Awareness: Inject project context if available
        if let project = SDKProjectManager.shared.currentProject {
            audit("Project Context", detail: "Planning for project: \(project.name) (v\(project.version))", outcome: "aware")
        }

        if currentProfile == .precise {
            steps.append(PersonaAgentPlanStep(intent: .inspect, description: "Deep analysis for \(target)", requiredScopes: [.workspaceRead]))
        }

        switch intent {
        case .install:
            steps.append(PersonaAgentPlanStep(intent: .resolve, description: "Resolve dependencies for \(target)", tool: .resolveDependencies, requiredScopes: [.sdkManagePackages]))
            steps.append(PersonaAgentPlanStep(intent: .install, description: "Install \(target)", tool: .installPackage, parameters: ["name": target, "version": "1.0.0"], requiredScopes: [.sdkManagePackages, .sdkManageLibraries]))
        case .resolve:
            steps.append(PersonaAgentPlanStep(intent: .resolve, description: "Analyze dependency graph for \(target)", tool: .resolveDependencies, requiredScopes: [.sdkManagePackages]))
        case .execute:
            steps.append(PersonaAgentPlanStep(intent: .resolve, description: "Verify dependencies for \(target)", tool: .resolveDependencies, requiredScopes: [.sdkManagePackages]))
            steps.append(PersonaAgentPlanStep(intent: .execute, description: "Execute \(target) in sandbox", tool: .executeFramework, parameters: ["name": target], requiredScopes: [.frameworkExecute]))
        case .inspect:
            steps.append(PersonaAgentPlanStep(intent: .inspect, description: "Inspect \(target)", requiredScopes: [.workspaceRead]))
        case .takeover:
            steps.append(PersonaAgentPlanStep(intent: .takeover, description: "Request workspace takeover", requiredScopes: [.agentTakeover, .agentExecute]))
        case .rollback:
            steps.append(PersonaAgentPlanStep(intent: .rollback, description: "Rollback changes for \(target)", requiredScopes: [.workspaceWrite]))
        }

        currentPlan = steps
        audit("Plan Built", detail: "\(steps.count) steps for intent=\(intent.rawValue) target=\(target)", outcome: "ready")
        return steps
    }

    // MARK: - Tool Execution Pipeline (token + scope validated per step)

    func executeTool(_ tool: AgentToolName, parameters: [String: String], dryRun: Bool = false) -> UIAgentToolResult {
        guard tokenEngine.currentToken != nil else {
            audit("Tool Blocked", detail: tool.rawValue, outcome: "no_token")
            return .failure("No valid token — execution blocked")
        }
        guard tokenEngine.requireScope(tool.requiredScope) else {
            audit("Tool Blocked", detail: tool.rawValue, outcome: "scope_denied")
            return .failure("Missing scope: \(tool.requiredScope.rawValue)")
        }

        if dryRun {
            let result = UIAgentToolResult.dryRun("DRY RUN: \(tool.displayName) with \(parameters)")
            logInvocation(tool: tool, parameters: parameters, result: result)
            audit("Dry Run", detail: tool.rawValue, outcome: "simulated")
            return result
        }

        let result: UIAgentToolResult
        switch tool {
        case .installPackage: result = executeInstallPackage(parameters)
        case .resolveDependencies: result = executeResolveDependencies(parameters)
        case .installLibrary: result = executeInstallLibrary(parameters)
        case .invokeLibrary: result = executeInvokeLibrary(parameters)
        case .attachFramework: result = executeAttachFramework(parameters)
        case .executeFramework: result = executeExecuteFramework(parameters)
        case .createNote: result = executeCreateNote(parameters)
        case .sendEmail: result = executeSendEmail(parameters)
        case .createSlides: result = executeCreateSlides(parameters)
        case .updateTask: result = executeUpdateTask(parameters)
        case .managePackages: result = executeManagePackages(parameters)
        }
        logInvocation(tool: tool, parameters: parameters, result: result)
        return result
    }

    // MARK: - Agent Takeover (agentTakeoverWorkspace)

    func requestTakeover() -> Bool {
        guard tokenEngine.requireScope(.agentTakeover) else {
            audit("Takeover Denied", detail: "Missing agent.takeover scope", outcome: "blocked")
            return false
        }
        executionState = .awaitingApproval
        audit("Takeover Requested", detail: "Awaiting user approval", outcome: "pending")
        return true
    }

    func approveTakeover(grantedScopes: Set<SDKScope>) {
        takeoverScopes = grantedScopes
        takeoverActive = true
        executionState = .takenOver

        if let token = tokenEngine.currentToken {
            let allScopes = SDKScope.decode(token.payload.scp).union(grantedScopes)
            _ = tokenEngine.generateToken(
                developerId: token.payload.devId,
                scopes: allScopes,
                sessionDuration: token.payload.exp - Date().timeIntervalSince1970,
                deviceFingerprint: token.payload.dfp
            )
        }
        audit("Takeover Approved", detail: "Granted \(grantedScopes.count) scopes", outcome: "active")
    }

    func releaseTakeover() {
        takeoverActive = false
        takeoverScopes.removeAll()
        executionState = .idle
        audit("Takeover Released", detail: "Workspace control returned to user", outcome: "released")
    }

    // MARK: - Plan Execution (token validated per step)

    func executePlan() async {
        executionState = .executing
        for index in currentPlan.indices {
            if currentPlan[index].status == .completed { continue }

            var attempts = 0
            let maxRetries = 3
            var success = false

            while attempts < maxRetries && !success {
                currentPlan[index].status = .executing
                attempts += 1

                let missingScopes = currentPlan[index].requiredScopes.filter { !tokenEngine.hasScope($0) }
                if !missingScopes.isEmpty {
                    currentPlan[index].status = .failed
                    executionState = .failed
                    audit("Plan Step Failed", detail: currentPlan[index].description, outcome: "missing_scopes: \(missingScopes.map(\.rawValue))")
                    return
                }

                try? await Task.sleep(nanoseconds: 50_000_000 * UInt64(attempts))

                if let tool = currentPlan[index].tool {
                    let result = executeTool(tool, parameters: currentPlan[index].parameters ?? [:])
                    switch result {
                    case .success:
                        success = true
                    case .failure(let error):
                        audit("Tool Execution Failed", detail: error, outcome: "retry")
                    case .dryRun:
                        success = true
                    }
                } else {
                    success = true
                }

                if success {
                    currentPlan[index].status = .completed
                    audit("Plan Step Completed", detail: currentPlan[index].description, outcome: "success (attempt \(attempts))")
                }
            }

            if !success {
                currentPlan[index].status = .failed
                executionState = .failed
                return
            }
        }
        executionState = .completed
        audit("Plan Execution Complete", detail: "\(currentPlan.count) steps", outcome: "success")
    }

    // MARK: - Rollback Engine

    func rollbackPlan() {
        for index in currentPlan.indices.reversed() {
            if currentPlan[index].status == .completed || currentPlan[index].status == .failed {
                currentPlan[index].status = .rolledBack
                audit("Rollback Step", detail: currentPlan[index].description, outcome: "rolled_back")
            }
        }
        executionState = .rolledBack
        audit("Rollback Complete", detail: "\(currentPlan.count) steps reversed", outcome: "rolled_back")
    }

    // MARK: - Dependency Awareness

    func inspectInstalledLibraries() -> [LibraryDescriptor] {
        LibraryRegistry.shared.libraries
    }

    func inspectInstalledFrameworks() -> [FrameworkDescriptor] {
        FrameworkRegistry.shared.frameworks
    }

    func inspectInstalledPackages() -> [PackageDescriptor] {
        PackageRegistry.shared.packages
    }

    func resolveMissingDependencies(for frameworkId: UUID) -> [String] {
        guard let fw = FrameworkRegistry.shared.framework(by: frameworkId) else { return [] }
        let installed = Set(PackageRegistry.shared.packages.map(\.id))
        return fw.packageDependencies.filter { !installed.contains($0) }.map(\.uuidString)
    }

    // MARK: - Private Tool Implementations

    private func executeInstallPackage(_ params: [String: String]) -> UIAgentToolResult {
        guard let name = params["name"], let version = params["version"] else {
            return .failure("Missing required parameters: name, version")
        }
        let hash = PackageIntegrityEngine.computeHash(name: name, version: version, exports: [])
        let pkg = PackageDescriptor(name: name, version: version, layer: .core, exports: params["exports"]?.components(separatedBy: ",") ?? [], dependencyIds: [], integrityHash: hash)
        PackageRegistry.shared.install(pkg)
        audit("Package Installed", detail: "\(name)@\(version)", outcome: "success")
        return .success("Installed \(name)@\(version)")
    }

    private func executeResolveDependencies(_ params: [String: String]) -> UIAgentToolResult {
        let graph = PackageRegistry.shared.buildDependencyGraph()
        if let cycle = graph.detectCycle() {
            return .failure("Circular dependency detected: \(cycle.joined(separator: " -> "))")
        }
        let resolved = graph.topologicalSort()
        return .success("Resolved \(resolved.count) packages in order")
    }

    private func executeInstallLibrary(_ params: [String: String]) -> UIAgentToolResult {
        guard let name = params["name"], let version = params["version"] else {
            return .failure("Missing required parameters: name, version")
        }
        let lib = LibraryDescriptor(name: name, version: version, channel: .stable, capabilities: params["capabilities"]?.components(separatedBy: ",") ?? [], requiredScopes: [.sdkManageLibraries])
        LibraryRegistry.shared.install(lib)
        audit("Library Installed", detail: "\(name)@\(version)", outcome: "success")
        return .success("Installed library \(name)@\(version)")
    }

    private func executeInvokeLibrary(_ params: [String: String]) -> UIAgentToolResult {
        guard let libraryId = params["id"], let uuid = UUID(uuidString: libraryId) else {
            return .failure("Invalid library ID")
        }
        guard let lib = LibraryRegistry.shared.library(by: uuid) else {
            return .failure("Library not found")
        }
        return LibraryExecutionBridge.invoke(library: lib, input: params)
    }

    private func executeAttachFramework(_ params: [String: String]) -> UIAgentToolResult {
        guard let name = params["name"] else {
            return .failure("Missing framework name")
        }
        let langStr = params["language"] ?? "swift"
        let lang = FrameworkLanguage(rawValue: langStr) ?? .swift
        let fw = FrameworkDescriptor(name: name, entryPoints: params["entryPoints"]?.components(separatedBy: ",") ?? ["main"], language: lang)
        FrameworkRegistry.shared.install(fw)
        audit("Framework Attached", detail: name, outcome: "success")
        return .success("Attached framework \(name)")
    }

    private func executeExecuteFramework(_ params: [String: String]) -> UIAgentToolResult {
        guard let frameworkId = params["id"], let uuid = UUID(uuidString: frameworkId) else {
            return .failure("Invalid framework ID")
        }
        guard let fw = FrameworkRegistry.shared.framework(by: uuid) else {
            return .failure("Framework not found")
        }
        let missing = resolveMissingDependencies(for: uuid)
        if !missing.isEmpty {
            return .failure("Unresolved dependencies: \(missing.joined(separator: ", "))")
        }
        return FrameworkSandboxRunner.execute(framework: fw, params: params)
    }

    private func executeCreateNote(_ params: [String: String]) -> UIAgentToolResult {
        guard let title = params["title"], let content = params["content"] else {
            return .failure("Missing title or content")
        }
        Task {
            _ = try? await ToolsKitSDK.shared.writeData(scope: .notes, title: title, payload: ["content": content])
        }
        audit("Note Created", detail: title, outcome: "success")
        return .success("Created note: \(title)")
    }

    private func executeSendEmail(_ params: [String: String]) -> UIAgentToolResult {
        guard let to = params["to"], let subject = params["subject"], let body = params["body"] else {
            return .failure("Missing email parameters")
        }
        Task {
            _ = try? await ToolsKitSDK.shared.writeData(scope: .emails, title: subject, payload: ["to": to, "body": body])
        }
        audit("Email Sent", detail: "To: \(to)", outcome: "success")
        return .success("Sent email to \(to)")
    }

    private func executeCreateSlides(_ params: [String: String]) -> UIAgentToolResult {
        guard let topic = params["topic"], let countStr = params["slideCount"], let count = Int(countStr) else {
            return .failure("Missing topic or slide count")
        }
        Task {
            _ = try? await ToolsKitSDK.shared.writeData(scope: .slides, title: topic, payload: ["slideCount": count])
        }
        audit("Slides Created", detail: "\(topic) (\(count) slides)", outcome: "success")
        return .success("Created \(count) slides on \(topic)")
    }

    private func executeUpdateTask(_ params: [String: String]) -> UIAgentToolResult {
        guard let id = params["id"], let status = params["status"] else {
            return .failure("Missing task ID or status")
        }
        Task {
            _ = try? await ToolsKitSDK.shared.writeData(scope: .tasks, title: "Update Task", payload: ["id": id, "status": status])
        }
        audit("Task Updated", detail: "ID: \(id) Status: \(status)", outcome: "success")
        return .success("Updated task \(id) to \(status)")
    }

    private func executeManagePackages(_ params: [String: String]) -> UIAgentToolResult {
        guard let action = params["action"], let package = params["package"] else {
            return .failure("Missing action or package name")
        }
        if action == "install" {
            _ = PackageDependencyManager.shared.installPackage(name: package, version: params["version"] ?? "1.0.0", exports: [], dependencyIds: [])
        } else if action == "uninstall" {
            if let pkg = PackageRegistry.shared.packages.first(where: { $0.name == package }) {
                _ = PackageDependencyManager.shared.uninstallPackage(id: pkg.id)
            }
        }
        audit("Package Managed", detail: "\(action) \(package)", outcome: "success")
        return .success("\(action.capitalized)ed package \(package)")
    }

    private func logInvocation(tool: AgentToolName, parameters: [String: String], result: UIAgentToolResult) {
        var invocation = AgentToolInvocation(tool: tool, parameters: parameters, timestamp: Date())
        invocation.result = result
        invocationLog.append(invocation)
    }

    private func audit(_ action: String, detail: String, outcome: String) {
        auditLog.append(AgentAuditEntry(timestamp: Date(), action: action, detail: detail, outcome: outcome))
    }

    func skipStep(index: Int) {
        guard index < currentPlan.count else { return }
        currentPlan[index].status = .completed // Mark as completed to skip
        audit("Step Skipped", detail: currentPlan[index].description, outcome: "manual_override")
    }
}

// MARK: - PersonaAgentFrameworkView

struct PersonaAgentFrameworkView: View {
    @StateObject private var agent = PersonaAgentFramework.shared
    @StateObject private var tokenEngine = DeterministicTokenEngine.shared
    @State private var intentInput = ""
    @State private var targetInput = ""
    @State private var showTakeoverSheet = false
    @State private var selectedTakeoverScopes: Set<SDKScope> = []
    @State private var showTokenInspector = false
    @State private var dryRunEnabled = false
    @State private var selectedTool: AgentToolName = .installPackage
    @State private var toolParams: [String: String] = [:]
    @State private var tokenGenUid = "agent-user"
    @State private var tokenGenScopes: Set<SDKScope> = Set(SDKScope.allCases)
    @State private var tokenGenDuration: Double = 1

    var body: some View {
        NavigationStack {
            List {
                tokenSection
                agentStateSection
                intentSection
                toolSection
                takeoverSection
                planSection
                auditSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Agent Framework")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showTokenInspector = true } label: { Label("Token", systemImage: "key") }
                }
            }
            .sheet(isPresented: $showTokenInspector) {
                NavigationStack {
                    tokenInspectorView
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showTokenInspector = false } } }
                }
            }
            .sheet(isPresented: $showTakeoverSheet) {
                NavigationStack {
                    takeoverApprovalView
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showTakeoverSheet = false } } }
                }
            }
        }
    }

    private var tokenSection: some View {
        Section("Authentication") {
            if let token = tokenEngine.currentToken {
                LabeledContent("Status") {
                    Text(token.isExpired ? "Expired" : "Active")
                        .foregroundStyle(token.isExpired ? .red : .green).font(.caption.bold())
                }
                LabeledContent("Session", value: String(token.payload.sid.prefix(8)) + "...")
                LabeledContent("Scopes", value: "\(SDKScope.decode(token.payload.scp).count)")
                Button("Revoke Token", role: .destructive) { tokenEngine.revokeToken() }
            } else {
                Text("No active token").foregroundStyle(.secondary)
                Button("Generate Token") {
                    _ = tokenEngine.generateToken(uid: tokenGenUid, scopes: tokenGenScopes, sessionDuration: tokenGenDuration * 3600, deviceFingerprint: UUID().uuidString)
                }.buttonStyle(.borderedProminent)
            }
        }
    }

    private var agentStateSection: some View {
        Section("Agent State") {
            Picker("Profile", selection: $agent.currentProfile) {
                ForEach(AgentExecutionProfile.allCases, id: \.self) { profile in
                    Text(profile.rawValue.capitalized).tag(profile)
                }
            }
            .pickerStyle(.menu)

            LabeledContent("Execution", value: agent.executionState.rawValue)
            LabeledContent("Takeover", value: agent.takeoverActive ? "Active" : "Inactive")
            LabeledContent("Plan Steps", value: "\(agent.currentPlan.count)")
            LabeledContent("Invocations", value: "\(agent.invocationLog.count)")
        }
    }

    private var intentSection: some View {
        Section("Intent Parser") {
            TextField("Describe what to do", text: $intentInput)
            TextField("Target (package/library/framework)", text: $targetInput)
            Button("Build Plan") {
                guard !intentInput.isEmpty, !targetInput.isEmpty else { return }
                _ = agent.buildPlan(for: agent.parseIntent(from: intentInput), target: targetInput)
            }.disabled(intentInput.isEmpty || targetInput.isEmpty)

            if !agent.currentPlan.isEmpty {
                Button("Execute Plan") { Task { await agent.executePlan() } }.disabled(agent.executionState == .executing)
                Button("Rollback Plan", role: .destructive) { agent.rollbackPlan() }
            }
        }
    }

    private var toolSection: some View {
        Section("Tool Execution") {
            Picker("Tool", selection: $selectedTool) {
                ForEach(AgentToolName.allCases) { tool in Text(tool.displayName).tag(tool) }
            }
            Toggle("Dry Run", isOn: $dryRunEnabled)
            TextField("name", text: binding(for: "name"))
            TextField("version", text: binding(for: "version"))
            TextField("id", text: binding(for: "id"))
            Button("Execute Tool") { _ = agent.executeTool(selectedTool, parameters: toolParams, dryRun: dryRunEnabled) }
        }
    }

    private var takeoverSection: some View {
        Section("Workspace Takeover") {
            if agent.takeoverActive {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Agent has workspace control").font(.caption.bold()).foregroundStyle(.orange)
                    Text("Granted: \(agent.takeoverScopes.map(\.rawValue).joined(separator: ", "))").font(.caption2)
                    Button("Release Control") { agent.releaseTakeover() }.buttonStyle(.bordered)
                }
            } else {
                Button("Request Takeover") { if agent.requestTakeover() { showTakeoverSheet = true } }
            }
        }
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Plan")
                .font(.headline)
                .padding(.horizontal)

            if !agent.currentPlan.isEmpty {
                ForEach(agent.currentPlan) { step in
                    HStack(spacing: 12) {
                        Image(systemName: stepIcon(step.status))
                            .foregroundColor(stepColor(step.status))
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.description)
                                .font(.subheadline)
                            Text(step.intent.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(step.status.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(stepColor(step.status).opacity(0.15))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            } else {
                Text("No active plan")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var auditSection: some View {
        Section("Audit Log (\(agent.auditLog.count))") {
            ForEach(agent.auditLog.suffix(20).reversed()) { entry in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.action).font(.caption.bold())
                        Spacer()
                        Text(entry.outcome).font(.caption2).foregroundStyle(entry.outcome == "success" ? .green : .orange)
                    }
                    Text(entry.detail).font(.caption2).foregroundStyle(.secondary)
                    Text(entry.timestamp.formatted(date: .omitted, time: .standard)).font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var tokenInspectorView: some View {
        List {
            if let token = tokenEngine.currentToken {
                Section("Header") {
                    LabeledContent("Type", value: token.header.tokenType)
                    LabeledContent("Algorithm", value: token.header.algorithm)
                    LabeledContent("Key ID", value: token.header.keyId)
                }
                Section("Payload") {
                    LabeledContent("UID", value: token.payload.uid)
                    LabeledContent("Session ID", value: String(token.payload.sid.prefix(12)))
                    LabeledContent("Nonce", value: String(token.payload.nonce.prefix(12)))
                    LabeledContent("Device FP", value: String(token.payload.dfp.prefix(12)))
                    LabeledContent("Version", value: token.payload.ver)
                    LabeledContent("Issued", value: Date(timeIntervalSince1970: token.payload.iat).formatted())
                    LabeledContent("Expires", value: Date(timeIntervalSince1970: token.payload.exp).formatted())
                }
                Section("Scopes") {
                    ForEach(Array(SDKScope.decode(token.payload.scp)).sorted(by: { $0.rawValue < $1.rawValue })) { scope in
                        Label(scope.displayName, systemImage: "checkmark.circle.fill").font(.caption)
                    }
                }
                Section("Signature") { Text(token.signature).font(.caption2.monospaced()).lineLimit(3) }
                Section("Serialized") { Text(token.serialized).font(.caption2.monospaced()).lineLimit(5) }
                Section("Validation") {
                    HStack {
                        Text("Status")
                        Spacer()
                        switch tokenEngine.validationStatus {
                        case .none: Text("Not Validated").foregroundStyle(.secondary)
                        case .valid: Text("Valid").foregroundStyle(.green).bold()
                        case .invalid(let reason): Text("Invalid: \(reason)").foregroundStyle(.red)
                        }
                    }.font(.caption)
                    Button("Validate Now") { _ = tokenEngine.validate(token: token, expectedFingerprint: token.payload.dfp) }
                }
            } else {
                Section("Generate Token") {
                    TextField("User ID", text: $tokenGenUid)
                    Stepper("Duration: \(Int(tokenGenDuration))h", value: $tokenGenDuration, in: 1...24)
                    ForEach(SDKScope.allCases) { scope in
                        Toggle(scope.displayName, isOn: Binding(get: { tokenGenScopes.contains(scope) }, set: { if $0 { tokenGenScopes.insert(scope) } else { tokenGenScopes.remove(scope) } })).font(.caption)
                    }
                    Button("Generate") {
                        _ = tokenEngine.generateToken(uid: tokenGenUid, scopes: tokenGenScopes, sessionDuration: tokenGenDuration * 3600, deviceFingerprint: UUID().uuidString)
                    }.buttonStyle(.borderedProminent)
                }
            }
            Section("Session Timeline (\(tokenEngine.sessionTimeline.count))") {
                ForEach(tokenEngine.sessionTimeline.suffix(15).reversed()) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.event).font(.caption.bold())
                        Text(event.detail).font(.caption2).foregroundStyle(.secondary)
                        Text(event.timestamp.formatted(date: .omitted, time: .standard)).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .navigationTitle("Token Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var takeoverApprovalView: some View {
        List {
            Section("Agent requests workspace control") {
                Text("Select scopes to grant the agent:").font(.caption)
            }
            Section("Scopes") {
                ForEach(SDKScope.allCases) { scope in
                    Toggle(scope.displayName, isOn: Binding(get: { selectedTakeoverScopes.contains(scope) }, set: { if $0 { selectedTakeoverScopes.insert(scope) } else { selectedTakeoverScopes.remove(scope) } })).font(.caption)
                }
            }
            Section {
                Button("Approve Takeover") {
                    agent.approveTakeover(grantedScopes: selectedTakeoverScopes)
                    showTakeoverSheet = false
                }.buttonStyle(.borderedProminent).disabled(selectedTakeoverScopes.isEmpty)
            }
        }
        .navigationTitle("Approve Takeover")
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(get: { toolParams[key] ?? "" }, set: { toolParams[key] = $0 })
    }

    private func stepIcon(_ status: PersonaAgentPlanStep.StepStatus) -> String {
        switch status {
        case .pending: return "circle"
        case .executing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .rolledBack: return "arrow.uturn.backward.circle"
        }
    }

    private func stepColor(_ status: PersonaAgentPlanStep.StepStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .executing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .rolledBack: return .orange
        }
    }
}
