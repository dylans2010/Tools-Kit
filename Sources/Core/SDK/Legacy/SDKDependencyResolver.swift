import Foundation

/// Resolves cross-system dependencies and ensures execution order correctness.
public final class SDKDependencyResolver {
    public static let shared = SDKDependencyResolver()

    private init() {}

    public func validate(action: SDKAction) throws {
        // Logic to ensure that prerequisites for an action are met.
        // E.g. can't delete a file if it doesn't exist (simulated).

        switch action {
        case .deleteFile(let id):
            let files = WorkspaceAPI.shared.files.listFiles()
            guard files.contains(where: { $0.id == id }) else {
                throw DependencyError.missingRequirement("File with ID \(id) not found")
            }
        case .generateSlideContent(let deckID, _):
            let decks = WorkspaceAPI.shared.slides.listDecks()
            guard decks.contains(where: { $0.id == deckID }) else {
                throw DependencyError.missingRequirement("Slide Deck with ID \(deckID) not found")
            }
        default:
            break
        }
    }
}

public enum DependencyError: Error, LocalizedError, Sendable {
    case missingRequirement(String)

    public var errorDescription: String? {
        switch self {
        case .missingRequirement(let msg): return "Dependency Error: \(msg)"
        }
    }
}
