import Foundation
import Combine
import CoreData

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

    private let context = SDKCoreDataStack.shared.context

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
        if let current = currentProject {
            if let index = projects.firstIndex(where: { $0.id == current.id }) {
                projects[index] = current
            }

            // CoreData Persistence
            let fetchRequest: NSFetchRequest<SDKProjectMO> = NSFetchRequest(entityName: "SDKProject")
            fetchRequest.predicate = NSPredicate(format: "id == %@", current.id as CVarArg)

            let mo: SDKProjectMO
            if let existing = try? context.fetch(fetchRequest).first {
                mo = existing
            } else {
                mo = SDKProjectMO(context: context)
                mo.id = current.id
            }

            mo.name = current.name
            mo.createdAt = current.createdAt
            mo.lastBuiltAt = current.lastBuiltAt
            mo.healthStatus = current.healthStatus.rawValue
            mo.enabledScopesJSON = try? String(data: JSONEncoder().encode(current.enabledScopes), encoding: .utf8)
            mo.enabledPluginIDsJSON = try? String(data: JSONEncoder().encode(current.enabledPluginIDs), encoding: .utf8)
            mo.enabledToolIDsJSON = try? String(data: JSONEncoder().encode(current.enabledToolIDs), encoding: .utf8)
            mo.enabledConnectorIDsJSON = try? String(data: JSONEncoder().encode(current.enabledConnectorIDs), encoding: .utf8)

            SDKCoreDataStack.shared.save()
        }

        SDKLogStore.shared.log("Project saved to CoreData", source: "SDKProjectManager", level: .info)
    }

    private func load() {
        let fetchRequest: NSFetchRequest<SDKProjectMO> = NSFetchRequest(entityName: "SDKProject")
        if let results = try? context.fetch(fetchRequest) {
            self.projects = results.map { mo in
                SDKProject(
                    id: mo.id ?? UUID(),
                    name: mo.name ?? "Unknown",
                    createdAt: mo.createdAt ?? Date(),
                    lastBuiltAt: mo.lastBuiltAt,
                    enabledScopes: mo.enabledScopesJSON?.data(using: .utf8).flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? [],
                    enabledPluginIDs: mo.enabledPluginIDsJSON?.data(using: .utf8).flatMap { try? JSONDecoder().decode([UUID].self, from: $0) } ?? [],
                    enabledToolIDs: mo.enabledToolIDsJSON?.data(using: .utf8).flatMap { try? JSONDecoder().decode([UUID].self, from: $0) } ?? [],
                    enabledConnectorIDs: mo.enabledConnectorIDsJSON?.data(using: .utf8).flatMap { try? JSONDecoder().decode([UUID].self, from: $0) } ?? [],
                    automationRules: [], // Rules handled by AutomationEngine
                    healthStatus: HealthStatus(rawValue: mo.healthStatus ?? "") ?? .healthy
                )
            }
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
