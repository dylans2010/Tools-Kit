import Foundation
import Combine
import SwiftUI

public enum SDKWorkspaceNode: String, CaseIterable, Codable, Hashable, Identifiable {
    case config
    case capabilities
    case scopes
    case libraries
    case dependencies
    case connectors
    case runtimeScripts
    case apiEndpoints

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .config: return "Config"
        case .capabilities: return "Capabilities"
        case .scopes: return "Scopes"
        case .libraries: return "Libraries"
        case .dependencies: return "Dependencies"
        case .connectors: return "Connectors"
        case .runtimeScripts: return "Runtime Scripts"
        case .apiEndpoints: return "API Endpoints"
        }
    }

    public var icon: String {
        switch self {
        case .config: return "gearshape.2"
        case .capabilities: return "square.grid.3x3.fill"
        case .scopes: return "lock.shield"
        case .libraries: return "books.vertical"
        case .dependencies: return "point.3.connected.trianglepath.dotted"
        case .connectors: return "link"
        case .runtimeScripts: return "terminal"
        case .apiEndpoints: return "network"
        }
    }

    public var tags: [String] {
        switch self {
        case .config: return ["core", "project"]
        case .capabilities: return ["matrix", "runtime"]
        case .scopes: return ["permissions", "security"]
        case .libraries: return ["modules", "shared"]
        case .dependencies: return ["graph", "ordering"]
        case .connectors: return ["external", "integration"]
        case .runtimeScripts: return ["automation", "pipeline"]
        case .apiEndpoints: return ["http", "routes"]
        }
    }
}


public struct SDKScopeDefinition: Identifiable, Codable, Hashable {
    public var id: String { key }
    public var key: String
    public var category: String
    public var description: String
    public var riskLevel: String
    public var approvals: String
    public var linkedCapability: SDKWorkspaceNode
    public var dependsOn: [String]

    public init(
        key: String,
        category: String,
        description: String,
        riskLevel: String,
        approvals: String,
        linkedCapability: SDKWorkspaceNode,
        dependsOn: [String] = []
    ) {
        self.key = key
        self.category = category
        self.description = description
        self.riskLevel = riskLevel
        self.approvals = approvals
        self.linkedCapability = linkedCapability
        self.dependsOn = dependsOn
    }
}

public struct SDKCapabilityDefinition: Identifiable, Codable, Hashable {
    public var id: SDKWorkspaceNode { node }
    public var node: SDKWorkspaceNode
    public var description: String
    public var requiredScopes: [String]

    public init(node: SDKWorkspaceNode, description: String, requiredScopes: [String]) {
        self.node = node
        self.description = description
        self.requiredScopes = requiredScopes
    }
}

public enum SDKPanelZone: String, Codable, CaseIterable {
    case left
    case center
    case right
    case bottom
    case top
}

public struct SDKWorkspaceLayout: Codable {
    public var leftSidebarWidth: Double
    public var rightInspectorWidth: Double
    public var bottomPanelHeight: Double
    public var isLeftCollapsed: Bool
    public var isRightCollapsed: Bool
    public var isBottomCollapsed: Bool

    public init(
        leftSidebarWidth: Double = 250,
        rightInspectorWidth: Double = 300,
        bottomPanelHeight: Double = 230,
        isLeftCollapsed: Bool = false,
        isRightCollapsed: Bool = false,
        isBottomCollapsed: Bool = false
    ) {
        self.leftSidebarWidth = leftSidebarWidth
        self.rightInspectorWidth = rightInspectorWidth
        self.bottomPanelHeight = bottomPanelHeight
        self.isLeftCollapsed = isLeftCollapsed
        self.isRightCollapsed = isRightCollapsed
        self.isBottomCollapsed = isBottomCollapsed
    }
}

public struct SDKEditorTab: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var node: SDKWorkspaceNode

    public init(id: UUID = UUID(), title: String, node: SDKWorkspaceNode) {
        self.id = id
        self.title = title
        self.node = node
    }
}

public struct SDKRuntimeDiagnostic: Identifiable, Codable, Hashable {
    public enum Severity: String, Codable {
        case warning
        case error
    }

    public let id: UUID
    public var severity: Severity
    public var node: SDKWorkspaceNode
    public var message: String
    public var suggestion: String

    public init(id: UUID = UUID(), severity: Severity, node: SDKWorkspaceNode, message: String, suggestion: String) {
        self.id = id
        self.severity = severity
        self.node = node
        self.message = message
        self.suggestion = suggestion
    }
}

public struct SDKLibraryFunctionExport: Identifiable, Codable, Hashable {
    public var id: String { name }
    public var name: String
    public var signature: String
}

public struct SDKLibraryDefinition: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var version: String
    public var linkedScopes: [String]
    public var dependencies: [String]
    public var exportedFunctions: [SDKLibraryFunctionExport]
    public var pipelineStages: [String]
    public var usageCount: Int

    public init(
        id: UUID = UUID(),
        name: String,
        version: String = "1.0.0",
        linkedScopes: [String] = [],
        dependencies: [String] = [],
        exportedFunctions: [SDKLibraryFunctionExport] = [],
        pipelineStages: [String] = [],
        usageCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.linkedScopes = linkedScopes
        self.dependencies = dependencies
        self.exportedFunctions = exportedFunctions
        self.pipelineStages = pipelineStages
        self.usageCount = usageCount
    }
}

public struct SDKDependencyNode: Identifiable, Codable, Hashable {
    public enum Kind: String, Codable, CaseIterable {
        case library
        case connector
        case plugin
        case sdkApp
    }

    public let id: UUID
    public var name: String
    public var kind: Kind
    public var version: String
    public var linkedTo: [UUID]
    public var requiredScopes: [String]
    public var preRunHook: String?
    public var postRunHook: String?
    public var lazyLoaded: Bool
    public var conditionalExpression: String

    public init(
        id: UUID = UUID(),
        name: String,
        kind: Kind,
        version: String = "1.0.0",
        linkedTo: [UUID] = [],
        requiredScopes: [String] = [],
        preRunHook: String? = nil,
        postRunHook: String? = nil,
        lazyLoaded: Bool = false,
        conditionalExpression: String = ""
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.version = version
        self.linkedTo = linkedTo
        self.requiredScopes = requiredScopes
        self.preRunHook = preRunHook
        self.postRunHook = postRunHook
        self.lazyLoaded = lazyLoaded
        self.conditionalExpression = conditionalExpression
    }
}

public struct SDKRunConfiguration: Identifiable, Codable, Hashable {
    public enum Mode: String, Codable, CaseIterable {
        case sandbox = "sandbox"
        case productionSafe = "production-safe"
        case noSandbox = "sdk.developer.noSandbox"
    }

    public let id: UUID
    public var name: String
    public var mode: Mode
    public var environmentPreset: String
    public var scopedExecution: [String]
    public var parallelSimulation: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        mode: Mode = .sandbox,
        environmentPreset: String = "Default",
        scopedExecution: [String] = [],
        parallelSimulation: Bool = false
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.environmentPreset = environmentPreset
        self.scopedExecution = scopedExecution
        self.parallelSimulation = parallelSimulation
    }
}

@MainActor
public final class SDKRuntimeWorkspaceState: ObservableObject {
    public static let shared = SDKRuntimeWorkspaceState()

    @Published public var layout = SDKWorkspaceLayout()
    @Published public var selectedNode: SDKWorkspaceNode = .config
    @Published public var openTabs: [SDKEditorTab] = [SDKEditorTab(title: "Config", node: .config)]
    @Published public var selectedTabID: UUID?
    @Published public var diagnostics: [SDKRuntimeDiagnostic] = []
    @Published public var libraries: [SDKLibraryDefinition] = []
    @Published public var dependencies: [SDKDependencyNode] = []
    @Published public var runConfigurations: [SDKRunConfiguration] = [SDKRunConfiguration(name: "Default Sandbox")]
    @Published public var selectedRunConfigurationID: UUID?
    @Published public var navigatorFilterText: String = ""
    @Published public var injectedPanels: [SDKPanelZone: String] = [:]
    @Published public var inspectorJSON: String = "{}"
    @Published public var memoryEstimateMB: Int = 0
    @Published public var runtimeFailureMessage: String?

    public static let scopeCatalog: [SDKScopeDefinition] = [
        SDKScopeDefinition(key: "workspace.files.read", category: "Data", description: "Read project files", riskLevel: "Low", approvals: "None", linkedCapability: .config),
        SDKScopeDefinition(key: "workspace.files.write", category: "Data", description: "Write project files", riskLevel: "Medium", approvals: "Maintainer", linkedCapability: .runtimeScripts, dependsOn: ["workspace.files.read"]),
        SDKScopeDefinition(key: "workspace.persona.read", category: "AI", description: "Use persona context", riskLevel: "Medium", approvals: "Maintainer", linkedCapability: .capabilities),
        SDKScopeDefinition(key: "workspace.persona.write", category: "AI", description: "Persist persona memory", riskLevel: "High", approvals: "Security review", linkedCapability: .libraries, dependsOn: ["workspace.persona.read"]),
        SDKScopeDefinition(key: "workspace.automation.execute", category: "Automation", description: "Run workflow scripts", riskLevel: "High", approvals: "Maintainer", linkedCapability: .runtimeScripts, dependsOn: ["workspace.files.read"]),
        SDKScopeDefinition(key: "external.api.unrestricted", category: "Integrations", description: "External connector access", riskLevel: "High", approvals: "Security review", linkedCapability: .connectors),
        SDKScopeDefinition(key: "workspace.runtime.admin", category: "System", description: "Runtime administration", riskLevel: "Critical", approvals: "Admin", linkedCapability: .config, dependsOn: ["workspace.files.read", "workspace.automation.execute"])
    ]

    public static let capabilityCatalog: [SDKCapabilityDefinition] = [
        SDKCapabilityDefinition(node: .config, description: "Project metadata, runtime defaults, and selected run configuration.", requiredScopes: ["workspace.files.read"]),
        SDKCapabilityDefinition(node: .capabilities, description: "SDK feature matrix driven by dependencies, libraries, and granted scopes.", requiredScopes: ["workspace.files.read"]),
        SDKCapabilityDefinition(node: .scopes, description: "Permission grants validated before SDK execution.", requiredScopes: ["workspace.files.read"]),
        SDKCapabilityDefinition(node: .libraries, description: "Callable SDK library exports and pipeline stages.", requiredScopes: ["workspace.files.read"]),
        SDKCapabilityDefinition(node: .dependencies, description: "Execution graph consumed by the SDK dependency planner.", requiredScopes: ["workspace.files.read"]),
        SDKCapabilityDefinition(node: .connectors, description: "External API and connector federation.", requiredScopes: ["external.api.unrestricted"]),
        SDKCapabilityDefinition(node: .runtimeScripts, description: "Automation flows and pre/post run hooks.", requiredScopes: ["workspace.automation.execute"]),
        SDKCapabilityDefinition(node: .apiEndpoints, description: "HTTP route explorer and SDK endpoint contracts.", requiredScopes: ["workspace.files.read"])
    ]

    private let persistenceKey = "sdk_ide_workspace_state_v1"

    private struct PersistedState: Codable {
        var layout: SDKWorkspaceLayout
        var selectedNode: SDKWorkspaceNode
        var openTabs: [SDKEditorTab]
        var libraries: [SDKLibraryDefinition]
        var dependencies: [SDKDependencyNode]
        var runConfigurations: [SDKRunConfiguration]
        var selectedRunConfigurationID: UUID?
    }

    private init() {
        load()
        selectedTabID = openTabs.first?.id
        if libraries.isEmpty {
            libraries = [
                SDKLibraryDefinition(
                    name: "CoreRuntime",
                    linkedScopes: ["workspace.files.read"],
                    exportedFunctions: [SDKLibraryFunctionExport(name: "boot", signature: "() -> Void")],
                    pipelineStages: ["validate", "execute", "publish"]
                )
            ]
        }
        if dependencies.isEmpty {
            dependencies = [
                SDKDependencyNode(name: "CoreRuntime", kind: .library, requiredScopes: ["workspace.files.read"])
            ]
        }
        if selectedRunConfigurationID == nil {
            selectedRunConfigurationID = runConfigurations.first?.id
        }
        recalculateDiagnostics()
        updateMemoryEstimate()
    }

    public func open(node: SDKWorkspaceNode) {
        selectedNode = node
        if let existing = openTabs.first(where: { $0.node == node }) {
            selectedTabID = existing.id
        } else {
            let tab = SDKEditorTab(title: node.title, node: node)
            openTabs.append(tab)
            selectedTabID = tab.id
        }
        save()
    }

    public func close(tabID: UUID) {
        openTabs.removeAll { $0.id == tabID }
        if selectedTabID == tabID {
            selectedTabID = openTabs.last?.id
            selectedNode = openTabs.last?.node ?? .config
        }
        save()
    }

    public func setSelected(tabID: UUID) {
        selectedTabID = tabID
        if let node = openTabs.first(where: { $0.id == tabID })?.node {
            selectedNode = node
        }
        save()
    }

    public var selectedRunConfiguration: SDKRunConfiguration? {
        runConfigurations.first { $0.id == selectedRunConfigurationID } ?? runConfigurations.first
    }

    public func effectiveScopes(for project: SDKProject?) -> Set<String> {
        var scopes = Set(project?.enabledScopes ?? [])
        scopes.formUnion(project?.requiredScopes ?? [])
        scopes.formUnion(selectedRunConfiguration?.scopedExecution ?? [])
        return scopes
    }

    @MainActor
    public func setScope(_ key: String, enabled: Bool, for projectManager: SDKProjectManager = .shared) {
        guard var project = projectManager.currentProject else { return }
        if enabled {
            grantScope(key, to: &project)
        } else {
            project.enabledScopes.removeAll { $0 == key }
        }
        projectManager.updateProject(project)
        syncSDKGraphFromProject(project)
        recalculateDiagnostics()
    }

    public func grantScope(_ key: String, to project: inout SDKProject) {
        guard !project.enabledScopes.contains(key) else { return }
        if let definition = Self.scopeCatalog.first(where: { $0.key == key }) {
            for dependency in definition.dependsOn {
                grantScope(dependency, to: &project)
            }
        }
        project.enabledScopes.append(key)
    }

    public func syncSDKGraphFromProject(_ project: SDKProject?) {
        guard let project else { return }
        for index in libraries.indices {
            libraries[index].usageCount = dependencies.filter { $0.name == libraries[index].name }.count
        }
        for library in libraries {
            if let dependencyIndex = dependencies.firstIndex(where: { $0.name == library.name && $0.kind == .library }) {
                dependencies[dependencyIndex].version = library.version
                dependencies[dependencyIndex].requiredScopes = library.linkedScopes
            } else {
                dependencies.append(SDKDependencyNode(name: library.name, kind: .library, version: library.version, requiredScopes: library.linkedScopes))
            }
        }
        save()
    }

    @MainActor
    public func syncSDKGraphFromProject() {
        syncSDKGraphFromProject(SDKProjectManager.shared.currentProject)
    }

    public func upsertLibrary(_ library: SDKLibraryDefinition) {
        if let index = libraries.firstIndex(where: { $0.id == library.id }) {
            libraries[index] = library
        } else {
            libraries.append(library)
        }
        if let dependencyIndex = dependencies.firstIndex(where: { $0.name == library.name && $0.kind == .library }) {
            dependencies[dependencyIndex].version = library.version
            dependencies[dependencyIndex].requiredScopes = library.linkedScopes
        } else {
            dependencies.append(SDKDependencyNode(name: library.name, kind: .library, version: library.version, requiredScopes: library.linkedScopes))
        }
        recalculateDiagnostics()
    }

    @MainActor
    public func recalculateDiagnostics() {
        var next: [SDKRuntimeDiagnostic] = []
        let project = SDKProjectManager.shared.currentProject
        let scopes = effectiveScopes(for: project)

        if scopes.isEmpty {
            next.append(.init(severity: .warning, node: .scopes, message: "Project has no enabled scopes.", suggestion: "Enable at least one read scope for runtime startup."))
        }

        for capability in Self.capabilityCatalog {
            let missing = Set(capability.requiredScopes).subtracting(scopes)
            if !missing.isEmpty {
                next.append(.init(
                    severity: capability.node == .connectors ? .warning : .error,
                    node: capability.node,
                    message: "\(capability.node.title) is missing required scopes: \(missing.sorted().joined(separator: ", ")).",
                    suggestion: "Grant the required scope from Scopes or add it to the selected run configuration."
                ))
            }
        }

        for definition in Self.scopeCatalog where scopes.contains(definition.key) {
            let missingParents = Set(definition.dependsOn).subtracting(scopes)
            if !missingParents.isEmpty {
                next.append(.init(
                    severity: .error,
                    node: .scopes,
                    message: "\(definition.key) is enabled without dependencies: \(missingParents.sorted().joined(separator: ", ")).",
                    suggestion: "Enable the dependent scopes so SDK validation can pass."
                ))
            }
        }

        for library in libraries {
            let missingScopes = Set(library.linkedScopes).subtracting(scopes)
            if !missingScopes.isEmpty {
                next.append(.init(
                    severity: .warning,
                    node: .libraries,
                    message: "\(library.name) has missing scopes: \(missingScopes.sorted().joined(separator: ", ")).",
                    suggestion: "Grant missing scopes or remove scope extensions from the library."
                ))
            }
            if library.exportedFunctions.isEmpty {
                next.append(.init(
                    severity: .warning,
                    node: .libraries,
                    message: "\(library.name) has no exported functions.",
                    suggestion: "Add at least one function export to make the library callable."
                ))
            }
        }

        let conflictResolver = SDKDependencyConflictResolver()
        next.append(contentsOf: conflictResolver.conflicts(in: dependencies).map {
            SDKRuntimeDiagnostic(severity: .warning, node: .dependencies, message: $0, suggestion: "Use the dependency resolution assistant to align versions.")
        })

        let brokenLinks = dependencies.filter { node in
            node.linkedTo.contains { linked in !dependencies.contains(where: { $0.id == linked }) }
        }
        for broken in brokenLinks {
            next.append(.init(
                severity: .error,
                node: .dependencies,
                message: "\(broken.name) has broken dependency links.",
                suggestion: "Reconnect missing nodes or remove invalid links."
            ))
        }

        diagnostics = next
        updateInspectorJSON()
        updateMemoryEstimate()
        save()
    }

    public func injectPanelContent(_ content: String, into zone: SDKPanelZone) {
        injectedPanels[zone] = content
    }

    public func executeGuarded<T>(_ operationName: String, _ block: @escaping () async throws -> T) async -> T? {
        do {
            runtimeFailureMessage = nil
            return try await block()
        } catch {
            runtimeFailureMessage = "\(operationName) failed: \(error.localizedDescription)"
            SDKLogStore.shared.log(runtimeFailureMessage ?? "Operation failed", source: "SDKRuntimeWorkspaceState", level: .error)
            return nil
        }
    }

    public func saveSnapshot() {
        save()
    }

    private func updateInspectorJSON() {
        let payload: [String: Any] = [
            "selectedNode": selectedNode.rawValue,
            "openTabs": openTabs.map { $0.title },
            "libraryCount": libraries.count,
            "dependencyCount": dependencies.count,
            "diagnosticCount": diagnostics.count
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let text = String(data: data, encoding: .utf8) {
            inspectorJSON = text
        }
    }

    private func updateMemoryEstimate() {
        let cost = (openTabs.count * 3) + (libraries.count * 5) + (dependencies.count * 6) + (diagnostics.count * 2)
        memoryEstimateMB = max(24, cost)
    }

    private func save() {
        let state = PersistedState(
            layout: layout,
            selectedNode: selectedNode,
            openTabs: openTabs,
            libraries: libraries,
            dependencies: dependencies,
            runConfigurations: runConfigurations,
            selectedRunConfigurationID: selectedRunConfigurationID
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let state = try? JSONDecoder().decode(PersistedState.self, from: data)
        else {
            return
        }

        layout = state.layout
        selectedNode = state.selectedNode
        openTabs = state.openTabs
        libraries = state.libraries
        dependencies = state.dependencies
        runConfigurations = state.runConfigurations.isEmpty ? [SDKRunConfiguration(name: "Default Sandbox")] : state.runConfigurations
        selectedRunConfigurationID = state.selectedRunConfigurationID
    }
}
