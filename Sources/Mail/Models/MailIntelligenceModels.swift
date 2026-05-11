import Foundation

/// Defines the classification intent of an email thread.
enum MailIntent: String, Codable, CaseIterable {
    case task = "task"
    case approval = "approval"
    case negotiation = "negotiation"
    case escalation = "escalation"
    case invoice = "invoice"
    case meeting = "meeting"
    case informational = "informational"
    case urgent = "urgent"
    case followUp = "follow_up"
    case unknown = "unknown"
}

/// Extracted entities from communication content.
struct ExtractedEntities: Codable {
    var people: [String] = []
    var organizations: [String] = []
    var deadlines: [Date] = []
    var deliverables: [String] = []
    var risks: [String] = []
    var locations: [String] = []
    var monetaryValues: [String] = []
}

/// Represents a node in the communication memory graph.
struct MemoryGraphNode: Identifiable, Codable {
    let id: UUID
    let type: NodeType
    let value: String
    let metadata: [String: String]
    let timestamp: Date

    enum NodeType: String, Codable {
        case person
        case organization
        case topic
        case decision
        case commitment
    }
}

/// Represents a relationship link in the memory graph.
struct MemoryGraphEdge: Identifiable, Codable {
    let id: UUID
    let sourceID: UUID
    let targetID: UUID
    let relationshipType: String
    let strength: Double
}

/// Workflow automation pipeline state.
struct WorkflowState: Identifiable, Codable {
    let id: UUID
    var name: String
    var steps: [MailWorkflowStep]
    var currentStepIndex: Int
    var status: WorkflowStatus
    var threadID: String

    enum WorkflowStatus: String, Codable {
        case pending, active, completed, failed, paused
    }
}

/// A single step in an automation workflow.
struct MailWorkflowStep: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var actionType: String
    var isCompleted: Bool
}

/// Analysis result for an attachment.
struct AttachmentIntelligence: Identifiable, Codable {
    let id: String
    let fileName: String
    let fileType: AttachmentType
    var ocrText: String?
    var extractedData: [String: String]?
    var summary: String?

    enum AttachmentType: String, Codable {
        case contract, receipt, dataset, code, media, document, unknown
    }
}

/// Scoring and attention data for thread prioritization.
struct AttentionScore: Codable {
    var totalScore: Double
    var factors: [FactorScore]

    struct FactorScore: Codable {
        let name: String
        let score: Double
        let weight: Double
    }
}

/// Negotiation state tracking for a thread.
struct NegotiationState: Codable {
    var currentPhase: NegotiationPhase
    var concessions: [String]
    var commitments: [String]
    var leverageAnalysis: String
    var suggestedStrategy: String

    enum NegotiationPhase: String, Codable {
        case exploration, bidding, bargaining, closing, settled, stalled
    }
}

/// Relationship intelligence profile for a contact.
struct RelationshipProfile: Codable {
    let email: String
    var displayName: String?
    var sentimentTrend: [Double]
    var healthScore: Double
    var topTopics: [String]
    var totalInteractionCount: Int
    var lastInteractionDate: Date
}

/// Decision intelligence for tracking outcomes.
struct DecisionEntry: Identifiable, Codable {
    let id: UUID
    let title: String
    let summary: String
    let timestamp: Date
    let threadID: String
    var lineageIDs: [UUID] // IDs of related decisions
}

/// Communication safety and simulation data.
struct SafetyAnalysis: Codable {
    let tone: String
    let riskLevel: RiskLevel
    let risks: [String]
    let suggestedToneAdjustment: String

    enum RiskLevel: String, Codable {
        case low, medium, high, critical
    }
}

/// Extracted knowledge from email content.
struct KnowledgeInsight: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let category: String
    let tags: [String]
    let sourceThreadID: String
}
