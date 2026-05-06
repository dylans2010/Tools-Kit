import Foundation

public enum HealthStatus: String, Codable {
    case healthy, degraded, critical, unknown
}

public struct SDKProject: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var sourceCode: String
    public var createdAt: Date
    public var lastBuiltAt: Date?
    public var enabledScopes: [SDKScope]
    public var enabledPluginIDs: [UUID]
    public var enabledToolIDs: [UUID]
    public var enabledConnectorIDs: [UUID]
    public var automationRules: [SDKAutomationRule]
    public var healthStatus: HealthStatus
    public var status: ProjectStatus

    public enum ProjectStatus: String, Codable {
        case idle, running, error, deployed
    }

    public init(id: UUID = UUID(), name: String, sourceCode: String = "", createdAt: Date = Date(), lastBuiltAt: Date? = nil, enabledScopes: [SDKScope] = [], enabledPluginIDs: [UUID] = [], enabledToolIDs: [UUID] = [], enabledConnectorIDs: [UUID] = [], automationRules: [SDKAutomationRule] = [], healthStatus: HealthStatus = .unknown, status: ProjectStatus = .idle) {
        self.id = id
        self.name = name
        self.sourceCode = sourceCode
        self.createdAt = createdAt
        self.lastBuiltAt = lastBuiltAt
        self.enabledScopes = enabledScopes
        self.enabledPluginIDs = enabledPluginIDs
        self.enabledToolIDs = enabledToolIDs
        self.enabledConnectorIDs = enabledConnectorIDs
        self.automationRules = automationRules
        self.healthStatus = healthStatus
        self.status = status
    }
}

@MainActor
public final class SDKProjectManager: ObservableObject {
    public static let shared = SDKProjectManager()

    @Published public var currentProject: SDKProject?
    @Published public var savedProjects: [SDKProject] = []

    private init() {
        loadProjects()
    }

    public func save() throws {
        if let current = currentProject {
            if let index = savedProjects.firstIndex(where: { $0.id == current.id }) {
                savedProjects[index] = current
            } else {
                savedProjects.append(current)
            }
        }

        try UnifiedDataStore.shared.save(savedProjects, key: "sdk_projects_v2")
        SDKLogStore.shared.log("Projects saved via UnifiedDataStore", source: "SDKProjectManager", level: .info)
    }

    public func updateHealth() {
        // Logic to update health status based on components (connectors, plugins)
        currentProject?.healthStatus = .healthy
        SDKLogStore.shared.log("Updated health status for current project", source: "SDKProjectManager", level: .info)
    }

    public func addAutomationRule(_ rule: SDKAutomationRule) {
        currentProject?.automationRules.append(rule)
    }

    public func removeAutomationRule(id: UUID) {
        currentProject?.automationRules.removeAll { $0.id == id }
    }

    private func loadProjects() {
        if let decoded = try? UnifiedDataStore.shared.load([SDKProject].self, key: "sdk_projects_v2") {
            self.savedProjects = decoded
            self.currentProject = decoded.first
        }
    }
}
