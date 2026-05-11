import Foundation

@MainActor
struct AISlidesOrchestrator {
    private let pipeline = AISlidesPipeline()
    private let retryProgressBase = 0.35
    private let retryProgressStep = 0.2

    func run(input: SlideInput, progress: @escaping (String, Double) -> Void) async -> SlideDeck {
        let maxAttempts = 2
        var attempt = 0
        var lastError: Error?

        while attempt <= maxAttempts {
            do {
                let deck = try await pipeline.run(input: input, progress: progress)
                if deck.slides.count >= 5 {
                    print("[SlidesPipeline] Success: generated \(deck.slides.count) slides")
                    return deck
                }
                print("[SlidesPipeline] Warning: only \(deck.slides.count) slides generated, retrying")
                attempt += 1
                if attempt > maxAttempts { return deck }
                progress("Retrying (insufficient slides) \(attempt)", min(0.95, retryProgressBase + (Double(attempt) * retryProgressStep)))
            } catch {
                lastError = error
                attempt += 1
                if attempt > maxAttempts { break }
                print("[SlidesPipeline] Error on attempt \(attempt): \(error.localizedDescription)")
                progress("Retrying stage \(attempt)", min(0.95, retryProgressBase + (Double(attempt) * retryProgressStep)))
            }
        }

        print("[SlidesPipeline] All attempts failed. Generating recovery fallback.")
        progress("Generating recovery fallback", 0.90)
        return await generateRecoveryFallback(input: input, lastError: lastError)
    }

    private func generateRecoveryFallback(input: SlideInput, lastError: Error?) -> SlideDeck {
        let topic = input.rawText.isEmpty ? "AI Slides" : input.rawText
        let slideCount = max(5, input.slideCount)

        var slides: [Slide] = []

        slides.append(Slide(
            type: "title",
            title: topic,
            layout: "centered",
            elements: [
                SlideElement(kind: .text),
            ],
            metadata: ["source": "recovery_fallback", "error": lastError?.localizedDescription ?? "unknown"]
        ))

        slides.append(Slide(
            type: "bullet",
            title: "Overview",
            layout: "verticalList",
            elements: [
                {
                    var el = SlideElement(kind: .bullets)
                    el.bullets = ["Topic: \(topic)", "Generated via recovery fallback", "AI pipeline encountered errors"]
                    return el
                }()
            ],
            metadata: ["source": "recovery_fallback"]
        ))

        slides.append(Slide(
            type: "bullet",
            title: "Key Points",
            layout: "verticalList",
            elements: [
                {
                    var el = SlideElement(kind: .bullets)
                    el.bullets = ["Content generation was attempted", "Multiple retry attempts made", "This fallback ensures output"]
                    return el
                }()
            ],
            metadata: ["source": "recovery_fallback"]
        ))

        slides.append(Slide(
            type: "bullet",
            title: "Details",
            layout: "verticalList",
            elements: [
                {
                    var el = SlideElement(kind: .bullets)
                    el.bullets = input.notes.isEmpty ? ["No additional notes provided"] : Array(input.notes.prefix(4))
                    return el
                }()
            ],
            metadata: ["source": "recovery_fallback"]
        ))

        slides.append(Slide(
            type: "bullet",
            title: "Next Steps",
            layout: "verticalList",
            elements: [
                {
                    var el = SlideElement(kind: .bullets)
                    el.bullets = ["Retry with more specific input", "Check API connectivity", "Review input formatting"]
                    return el
                }()
            ],
            metadata: ["source": "recovery_fallback"]
        ))

        while slides.count < slideCount {
            slides.append(Slide(
                type: "bullet",
                title: "Section \(slides.count)",
                layout: "verticalList",
                elements: [
                    {
                        var el = SlideElement(kind: .text)
                        el.text = "Generated content unavailable"
                        return el
                    }()
                ],
                metadata: ["source": "recovery_fallback"]
            ))
        }

        return SlideDeck(
            title: topic,
            theme: input.preferredThemeID ?? AIGenSlideCatalog.defaultThemeID,
            slides: slides,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
