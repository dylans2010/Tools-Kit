import Foundation
import Combine

public struct SDKProject: Identifiable, Codable {
    public enum ProjectStatus: String, Codable, CaseIterable {
        case active
        case draft
        case archived
    }

    public var id: UUID
    public var name: String
    public var description: String
    public var createdAt: Date
    public var updatedAt: Date
    public var lastBuiltAt: Date?
    public var version: Int
    public var status: ProjectStatus
    public var enabledScopes: [String]
    public var enabledPluginIDs: [String]
    public var enabledToolIDs: [String]
    public var enabledConnectorIDs: [String]
    public var automationRules: [SDKAutomationRule]
    public var healthStatus: HealthStatus
    public var sourceCode: String
    public var requiredScopes: [String]
    public var ownerIdentifier: String?
    public var vulnerabilityDatabase: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, createdAt, updatedAt, lastBuiltAt, version, status
        case enabledScopes, enabledPluginIDs, enabledToolIDs, enabledConnectorIDs
        case automationRules, healthStatus, sourceCode, requiredScopes, ownerIdentifier, vulnerabilityDatabase
    }

    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastBuiltAt: Date? = nil,
        version: Int = 1,
        status: ProjectStatus = .draft,
        enabledScopes: [String] = [],
        enabledPluginIDs: [String] = [],
        enabledToolIDs: [String] = [],
        enabledConnectorIDs: [String] = [],
        automationRules: [SDKAutomationRule] = [],
        healthStatus: HealthStatus = .healthy,
        sourceCode: String = "",
        requiredScopes: [String] = [],
        ownerIdentifier: String? = nil,
        vulnerabilityDatabase: [String: String]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastBuiltAt = lastBuiltAt
        self.version = version
        self.status = status
        self.enabledScopes = enabledScopes
        self.enabledPluginIDs = enabledPluginIDs
        self.enabledToolIDs = enabledToolIDs
        self.enabledConnectorIDs = enabledConnectorIDs
        self.automationRules = automationRules
        self.healthStatus = healthStatus
        self.sourceCode = sourceCode
        self.requiredScopes = requiredScopes
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        lastBuiltAt = try c.decodeIfPresent(Date.self, forKey: .lastBuiltAt)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        status = try c.decodeIfPresent(ProjectStatus.self, forKey: .status) ?? .draft
        enabledScopes = try c.decodeIfPresent([String].self, forKey: .enabledScopes) ?? []
        enabledPluginIDs = try c.decodeIfPresent([String].self, forKey: .enabledPluginIDs) ?? []
        enabledToolIDs = try c.decodeIfPresent([String].self, forKey: .enabledToolIDs) ?? []
        enabledConnectorIDs = try c.decodeIfPresent([String].self, forKey: .enabledConnectorIDs) ?? []
        automationRules = try c.decodeIfPresent([SDKAutomationRule].self, forKey: .automationRules) ?? []
        healthStatus = try c.decodeIfPresent(HealthStatus.self, forKey: .healthStatus) ?? .healthy
        sourceCode = try c.decodeIfPresent(String.self, forKey: .sourceCode) ?? ""
        requiredScopes = try c.decodeIfPresent([String].self, forKey: .requiredScopes) ?? []
        ownerIdentifier = try c.decodeIfPresent(String.self, forKey: .ownerIdentifier)
        vulnerabilityDatabase = try c.decodeIfPresent([String: String].self, forKey: .vulnerabilityDatabase)
    }
}

public enum HealthStatus: String, Codable {
    case healthy, degraded, critical, unknown
}

@MainActor
public final class SDKProjectManager: ObservableObject {
    public static let shared = SDKProjectManager()

    @Published public var currentProject: SDKProject?
    @Published public var projects: [SDKProject] = []

    private let fileName = "sdk_projects_v4.json"

    private init() {
        load()
        if projects.isEmpty {
            currentProject = createProject(name: "My Workspace App")
        } else {
            currentProject = projects.first
        }
    }

    @discardableResult
    public func createProject(name: String, description: String = "", status: SDKProject.ProjectStatus = .draft) -> SDKProject {
        let owner = SDKStorageManager.shared.getSecureValue(key: "last_user_id_hash")
        let project = SDKProject(name: name, description: description, status: status, ownerIdentifier: owner)
        projects.insert(project, at: 0)
        currentProject = project
        try? save()
        return project
    }

    public func updateProject(_ project: SDKProject) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        var updated = project
        updated.updatedAt = Date()
        projects[index] = updated
        if currentProject?.id == updated.id {
            currentProject = updated
        }
        try? save()
    }

    public func deleteProject(id: UUID) {
        projects.removeAll { $0.id == id }
        if currentProject?.id == id {
            currentProject = projects.first
        }
        try? save()
    }

    @discardableResult
    public func duplicateProject(id: UUID) -> SDKProject? {
        guard let original = projects.first(where: { $0.id == id }) else { return nil }
        var duplicate = original
        duplicate.id = UUID()
        duplicate.name = original.name + " Copy"
        duplicate.createdAt = Date()
        duplicate.updatedAt = Date()
        duplicate.lastBuiltAt = nil
        duplicate.status = .draft
        projects.insert(duplicate, at: 0)
        try? save()
        return duplicate
    }

    public func loadProject(id: UUID) {
        currentProject = projects.first(where: { $0.id == id })
    }

    public func filteredProjects(search: String, status: SDKProject.ProjectStatus?) -> [SDKProject] {
        projects.filter { project in
            if !search.isEmpty {
                let q = search.lowercased()
                if !project.name.lowercased().contains(q) && !project.description.lowercased().contains(q) {
                    return false
                }
            }
            if let status, project.status != status {
                return false
            }
            return true
        }
        .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func save() throws {
        if let current = currentProject, let index = projects.firstIndex(where: { $0.id == current.id }) {
            projects[index] = current
        }
        try WorkspacePersistence.shared.save(projects, to: fileName)
        SDKLogStore.shared.log("Project saved", source: "SDKProjectManager", level: .info)
    }

    private func load() {
        if let loaded = try? WorkspacePersistence.shared.load([SDKProject].self, from: fileName) {
            projects = loaded
        } else if let old = try? WorkspacePersistence.shared.load([SDKProject].self, from: "sdk_projects_v3.json") {
            projects = old
        }
    }

    public func markCurrentProjectSaved(incrementVersion: Bool = true) {
        guard var project = currentProject else { return }
        project.updatedAt = Date()
        if incrementVersion {
            project.version += 1
        }
        currentProject = project
        updateProject(project)
    }

    public func updateHealth() {
        guard var project = currentProject else { return }
        let connectorsStatus = SDKConnectorManager.shared.connectors.map { $0.status }
        if connectorsStatus.contains(.error) {
            project.healthStatus = .critical
        } else if connectorsStatus.contains(.disconnected) {
            project.healthStatus = .degraded
        } else {
            project.healthStatus = .healthy
        }
        updateProject(project)
    }

    public func addAutomationRule(_ rule: SDKAutomationRule) {
        guard var project = currentProject else { return }
        project.automationRules.append(rule)
        updateProject(project)
    }

    public func removeAutomationRule(id: UUID) {
        guard var project = currentProject else { return }
        project.automationRules.removeAll { $0.id == id }
        updateProject(project)
    }
}
