import Foundation

@MainActor
struct AISlidesOrchestrator: Sendable {
    private let pipeline = AISlidesPipeline()

    func run(input: SlideInput, progress: @escaping (String, Double) -> Void) async throws -> SlideDeck {
        let deck = try await pipeline.run(input: input, progress: progress)
        return deck
    }
}
