import Foundation

@MainActor
final class AISlidesManager: ObservableObject {
    static let shared = AISlidesManager()

    @Published private(set) var isGenerating = false
    @Published private(set) var progressMessage = "Idle"
    @Published private(set) var progressValue: Double = 0
    @Published private(set) var latestDeck: SlideDeck?
    @Published private(set) var latestScheme: GenSlidesScheme?
    @Published private(set) var lastError: String?

    private let orchestrator = AISlidesOrchestrator()
    private let framework = GenerationModelsSlidesFramework()

    private init() {}

    func generate(input: SlideInput) async -> SlideDeck {
        isGenerating = true
        lastError = nil
        latestScheme = nil
        progressMessage = "Starting controlled generation"
        progressValue = 0.1

        print("[AISlidesManager] Starting generation for: \(input.rawText.prefix(60))")

        // Primary path: GenSlidesScheme-based pipeline
        do {
            progressMessage = "Generating structured JSON"
            progressValue = 0.3
            let scheme = try await framework.generateSlides(input: input)
            latestScheme = scheme
            progressMessage = "Converting to deck"
            progressValue = 0.8
            let deck = scheme.toSlideDeck()
            progressMessage = "Complete"
            progressValue = 1.0
            print("[AISlidesManager] GenSlidesScheme success: \(deck.slides.count) slides")
            latestDeck = deck
            SlideDecksManager.shared.addDeck(deck)
            isGenerating = false
            return deck
        } catch {
            print("[AISlidesManager] GenSlidesScheme pipeline failed: \(error.localizedDescription), falling back to orchestrator")
            progressMessage = "Retrying with multi-stage pipeline"
            progressValue = 0.4
        }

        // Fallback: multi-stage orchestrator pipeline
        let deck = await orchestrator.run(input: input) { [weak self] message, value in
            guard let self else { return }
            self.progressMessage = message
            self.progressValue = value
        }

        if deck.slides.contains(where: { $0.metadata["source"] == "recovery_fallback" }) {
            lastError = "Pipeline failed after retries; recovery fallback was used."
            print("[AISlidesManager] Warning: fallback deck returned")
        } else {
            print("[AISlidesManager] Success: \(deck.slides.count) slides generated")
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
