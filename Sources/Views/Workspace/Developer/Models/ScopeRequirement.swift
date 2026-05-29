import Foundation

public struct ScopeRequirement: Identifiable, Codable, Hashable {
    public var id: UUID
    public var scopeIdentifier: String
    public var requiredTier: DeveloperTier
    public var requiredProfileFields: [String]
    public var requiresManualReview: Bool
    public var justificationPrompt: String

    public init(
        id: UUID = UUID(),
        scopeIdentifier: String,
        requiredTier: DeveloperTier = .community,
        requiredProfileFields: [String] = [],
        requiresManualReview: Bool = false,
        justificationPrompt: String = ""
    ) {
        self.id = id
        self.scopeIdentifier = scopeIdentifier
        self.requiredTier = requiredTier
        self.requiredProfileFields = requiredProfileFields
        self.requiresManualReview = requiresManualReview
        self.justificationPrompt = justificationPrompt
    }
}
