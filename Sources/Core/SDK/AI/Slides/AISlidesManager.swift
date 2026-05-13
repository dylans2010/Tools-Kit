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
    @Published private(set) var lastPipelineError: AISlidesPipelineError?

    private let framework = GenerationModelsSlidesFramework()

    private init() {}

    func generate(input: SlideInput) async throws -> SlideDeck {
        isGenerating = true
        lastError = nil
        lastPipelineError = nil
        latestScheme = nil
        progressMessage = "Starting generation"
        progressValue = 0.1

        defer { isGenerating = false }

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
            latestDeck = deck
            SlideDecksManager.shared.addDeck(deck)
            return deck
        } catch let error as AISlidesPipelineError {
            lastPipelineError = error
            lastError = error.localizedDescription
            throw error
        } catch let error as SlideValidationError {
            lastError = error.localizedDescription
            throw error
        } catch {
            lastError = error.localizedDescription
            throw AISlidesPipelineError.providerFailure(
                code: (error as NSError).code,
                message: error.localizedDescription
            )
        }
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
    public func generateSlides(input: SlideInput) async throws -> SlideDeck {
        try await AISlidesManager.shared.generate(input: input)
    }
}
