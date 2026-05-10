import Foundation

struct IntegrationWorkflow: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var isEnabled: Bool = true
    var trigger: IntegrationTrigger
    var conditions: [IntegrationCondition] = []
    var actions: [IntegrationAction]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct IntegrationTrigger: Codable {
    var id: UUID = UUID()
    var type: TriggerType
    var source: String // e.g. "github", "note.created"
    var parameters: [String: String] = [:]
}

enum TriggerType: String, Codable {
    case external = "external"
    case internalApp = "internal"
    case scheduled = "scheduled"
}

struct IntegrationAction: Codable, Identifiable {
    var id: UUID = UUID()
    var type: ActionType
    var destination: String // e.g. "slack", "task.create"
    var parameters: [String: String] = [:]
}

enum ActionType: String, Codable {
    case external = "external"
    case internalApp = "internal"
}

struct IntegrationCondition: Codable {
    var field: String
    var `operator`: String // e.g. "contains", "equals"
    var value: String
}

struct IntegrationConnection: Codable, Identifiable {
    var id: UUID = UUID()
    var service: String // e.g. "Slack", "Gmail"
    var accountName: String
    var isAuthorized: Bool
    var authData: [String: String] = [:]
}

struct IntegrationHistoryEntry: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let time: String
}
