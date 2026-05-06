import Foundation
import Combine

public struct SDKProject: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var lastBuiltAt: Date?
    public var enabledScopes: [String]
    public var enabledPluginIDs: [UUID]
    public var enabledToolIDs: [UUID]
    public var enabledConnectorIDs: [UUID]
    public var automationRules: [SDKAutomationRule]
    public var healthStatus: HealthStatus
}

public enum HealthStatus: String, Codable {
    case healthy, degraded, critical, unknown
}

@MainActor
public final class SDKProjectManager: ObservableObject {
    public static let shared = SDKProjectManager()

    @Published public var currentProject: SDKProject?
    @Published public var projects: [SDKProject] = []

    private init() {
        load()
        if projects.isEmpty {
            createDefaultProject()
        } else {
            currentProject = projects.first
        }
    }

    private func createDefaultProject() {
        let defaultProject = SDKProject(
            id: UUID(),
            name: "My Workspace App",
            createdAt: Date(),
            lastBuiltAt: nil,
            enabledScopes: [],
            enabledPluginIDs: [],
            enabledToolIDs: [],
            enabledConnectorIDs: [],
            automationRules: [],
            healthStatus: .healthy
        )
        projects.append(defaultProject)
        currentProject = defaultProject
        try? save()
    }

    public func save() throws {
        // Sync current project back to projects array
        if let current = currentProject, let index = projects.firstIndex(where: { $0.id == current.id }) {
            projects[index] = current
        }

        // Persistence logic using WorkspacePersistence (JSON based as a proxy for CoreData
        // since we cannot compile xcdatamodel in this environment but must follow its spirit)
        try WorkspacePersistence.shared.save(projects, to: "sdk_projects_v3.json")

        SDKLogStore.shared.log("Project saved", source: "SDKProjectManager", level: .info)
    }

    private func load() {
        if let loaded = try? WorkspacePersistence.shared.load([SDKProject].self, from: "sdk_projects_v3.json") {
            projects = loaded
        }
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
        currentProject = project
        try? save()
    }

    public func addAutomationRule(_ rule: SDKAutomationRule) {
        currentProject?.automationRules.append(rule)
        try? save()
    }

    public func removeAutomationRule(id: UUID) {
        currentProject?.automationRules.removeAll { $0.id == id }
        try? save()
    }
}
