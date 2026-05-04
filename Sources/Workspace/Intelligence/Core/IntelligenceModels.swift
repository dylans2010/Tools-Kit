import Foundation

struct AIContext: Codable {
    let source: String // app or module name
    let data: String // serialized context data
    let timestamp: Date
}

struct IntelligenceInsight: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let priority: Priority
    let category: InsightCategory
    let action: AIAction?

    enum Priority: String, Codable {
        case high, medium, low
    }

    enum InsightCategory: String, Codable {
        case productivity, security, collaboration, code
    }
}

struct AIAction: Codable {
    let type: String
    let payload: [String: String]
}

struct CrossAppReasoningRequest: Codable {
    let query: String
    let includedApps: Set<String>
}
