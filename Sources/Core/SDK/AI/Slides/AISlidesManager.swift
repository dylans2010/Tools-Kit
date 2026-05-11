import Foundation

@MainActor
final class AISlidesManager: ObservableObject {
    static let shared = AISlidesManager()

    @Published private(set) var isGenerating = false
    @Published private(set) var progressMessage = "Idle"
    @Published private(set) var progressValue: Double = 0
    @Published private(set) var latestDeck: SlideDeck?

    private let orchestrator = AISlidesOrchestrator()

    private init() {}

    func generate(input: SlideInput) async -> SlideDeck {
        isGenerating = true
        progressMessage = "Starting"
        progressValue = 0

        let deck = await orchestrator.run(input: input) { [weak self] message, value in
            guard let self else { return }
            self.progressMessage = message
            self.progressValue = value
        }

        latestDeck = deck
        SlideDecksManager.shared.addDeck(deck)
        isGenerating = false
        return deck
    }
}

public struct WorkspaceSDKAI {
    public let slidesScope = AISlidesScope()
    public let slidesThemeScope = AISlidesThemeScope()

    public init() {}

    @MainActor
    public var isThemeScopeEnabled: Bool {
        let scopes = SDKScopeManager.shared.authorizedScopes
        if scopes.isEmpty || scopes.contains("*") {
            return true
        }
        if scopes.contains(slidesThemeScope.identifier) {
            return true
        }
        if scopes.contains("sdk.AI.generateSlides.*") {
            return true
        }
        return false
    }

    @MainActor
    public func generateSlides(input: SlideInput) async -> SlideDeck {
        await AISlidesManager.shared.generate(input: input)
    }
}
