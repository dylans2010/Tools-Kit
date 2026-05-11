import Foundation

@MainActor
struct AISlidesOrchestrator {
    private let pipeline = AISlidesPipeline()
    private let retryProgressBase = 0.35
    private let retryProgressStep = 0.2

    func run(input: SlideInput, progress: @escaping (String, Double) -> Void) async -> SlideDeck {
        let maxAttempts = 2
        var attempt = 0
        while attempt <= maxAttempts {
            do {
                return try await pipeline.run(input: input, progress: progress)
            } catch {
                attempt += 1
                if attempt > maxAttempts {
                    break
                }
                progress("Retrying stage \(attempt)", min(0.95, retryProgressBase + (Double(attempt) * retryProgressStep)))
            }
        }

        return SlideDeck(title: input.rawText.isEmpty ? "AI Slides" : input.rawText, slides: [Slide.blank(title: "Recovery Slide")])
    }
}
