import Foundation
import Combine

@MainActor
public final class AISlidesNarrationEngine: ObservableObject {
    public static let shared = AISlidesNarrationEngine()

    @Published public private(set) var isGenerating = false
    @Published public private(set) var generatedNotes: [UUID: String] = [:]
    @Published public private(set) var narrationScripts: [NarrationScript] = []
    @Published public private(set) var progress: Double = 0

    private init() {}

    // MARK: - Speaker Notes Generation

    public func generateSpeakerNotes(for deck: SlideDeck, style: NarrationStyle = .professional) async -> [SlideNarration] {
        isGenerating = true
        progress = 0
        defer {
            isGenerating = false
            progress = 1.0
        }

        var narrations: [SlideNarration] = []

        for (index, slide) in deck.slides.enumerated() {
            progress = Double(index) / Double(deck.slides.count)
            let notes = generateNotesForSlide(slide, index: index, total: deck.slides.count, style: style)
            let narration = SlideNarration(slideIndex: index, slideTitle: slide.title, speakerNotes: notes, estimatedDuration: estimateDuration(notes))
            narrations.append(narration)
            generatedNotes[slide.id] = notes
        }

        let script = NarrationScript(deckID: deck.id, deckTitle: deck.title, narrations: narrations, style: style)
        narrationScripts.append(script)

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "slides.narration",
            name: "notes.generated",
            data: ["deck": deck.id.uuidString, "slides": "\(narrations.count)"]
        ))

        return narrations
    }

    // MARK: - Script Export

    public func exportScript(deckID: UUID) -> String? {
        guard let script = narrationScripts.first(where: { $0.deckID == deckID }) else { return nil }

        var output = "PRESENTATION SCRIPT: \(script.deckTitle)\n"
        output += "Style: \(script.style.rawValue.capitalized)\n"
        output += "Total Duration: ~\(formatDuration(script.totalDuration))\n"
        output += String(repeating: "=", count: 60) + "\n\n"

        for narration in script.narrations {
            output += "--- SLIDE \(narration.slideIndex + 1): \(narration.slideTitle) ---\n"
            output += "Duration: ~\(formatDuration(narration.estimatedDuration))\n\n"
            output += narration.speakerNotes + "\n\n"
        }

        return output
    }

    // MARK: - Timing

    public func estimatePresentationDuration(deck: SlideDeck) -> TimeInterval {
        deck.slides.reduce(0) { total, slide in
            let bulletTime = Double(slide.bullets.count) * 15.0
            let baseTime = 30.0
            return total + baseTime + bulletTime
        }
    }

    public func createTimingPlan(deck: SlideDeck, totalMinutes: Double) -> [SlideTiming] {
        let totalSeconds = totalMinutes * 60
        let totalBullets = deck.slides.reduce(0) { $0 + $1.bullets.count }
        let basePerSlide = totalSeconds * 0.3 / Double(deck.slides.count)
        let perBullet = totalBullets > 0 ? (totalSeconds * 0.7) / Double(totalBullets) : 0

        return deck.slides.enumerated().map { index, slide in
            let duration = basePerSlide + Double(slide.bullets.count) * perBullet
            return SlideTiming(slideIndex: index, slideTitle: slide.title, allocatedDuration: duration, bulletCount: slide.bullets.count)
        }
    }

    // MARK: - Private

    private func generateNotesForSlide(_ slide: Slide, index: Int, total: Int, style: NarrationStyle) -> String {
        var notes = ""

        if index == 0 {
            notes += openingLine(style: style, title: slide.title)
        } else {
            notes += transitionLine(style: style, slideNumber: index + 1, total: total)
        }

        notes += "\n\n"
        notes += "Key points to cover:\n"
        for bullet in slide.bullets {
            notes += "  - \(expandBullet(bullet, style: style))\n"
        }

        if index == total - 1 {
            notes += "\n" + closingLine(style: style)
        }

        return notes
    }

    private func openingLine(style: NarrationStyle, title: String) -> String {
        switch style {
        case .professional:
            return "Good [morning/afternoon]. Today I will be presenting on \"\(title)\". Let me walk you through the key points."
        case .casual:
            return "Hey everyone! Let's talk about \"\(title)\"."
        case .academic:
            return "In this presentation, we examine \"\(title)\" through a structured analysis."
        case .storytelling:
            return "Imagine a world where \"\(title)\" transforms how we work. Let me tell you that story."
        case .minimal:
            return title
        }
    }

    private func transitionLine(style: NarrationStyle, slideNumber: Int, total: Int) -> String {
        switch style {
        case .professional:
            return "Moving on to point \(slideNumber) of \(total)."
        case .casual:
            return "Next up..."
        case .academic:
            return "Proceeding to the next section of our analysis."
        case .storytelling:
            return "And this brings us to the next chapter..."
        case .minimal:
            return ""
        }
    }

    private func closingLine(style: NarrationStyle) -> String {
        switch style {
        case .professional:
            return "In summary, these are the key takeaways. I am happy to take any questions."
        case .casual:
            return "That's a wrap! Any questions?"
        case .academic:
            return "To conclude, the evidence presented supports our thesis. Questions are welcome."
        case .storytelling:
            return "And that brings our story to its conclusion. What questions do you have?"
        case .minimal:
            return "Questions?"
        }
    }

    private func expandBullet(_ bullet: String, style: NarrationStyle) -> String {
        switch style {
        case .professional, .academic:
            return "Elaborate on: \(bullet)"
        case .casual, .storytelling:
            return "Talk about: \(bullet)"
        case .minimal:
            return bullet
        }
    }

    private func estimateDuration(_ text: String) -> TimeInterval {
        let wordCount = text.split(separator: " ").count
        return Double(wordCount) / 2.5
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(minutes)m \(secs)s"
    }
}

// MARK: - Models

public struct SlideNarration: Identifiable, Sendable {
    public let id = UUID()
    public let slideIndex: Int
    public let slideTitle: String
    public let speakerNotes: String
    public let estimatedDuration: TimeInterval
}

public struct NarrationScript: Identifiable, Sendable {
    public let id = UUID()
    public let deckID: UUID
    public let deckTitle: String
    public let narrations: [SlideNarration]
    public let style: NarrationStyle
    public let createdAt: Date

    public var totalDuration: TimeInterval {
        narrations.reduce(0) { $0 + $1.estimatedDuration }
    }

    public init(deckID: UUID, deckTitle: String, narrations: [SlideNarration], style: NarrationStyle) {
        self.deckID = deckID
        self.deckTitle = deckTitle
        self.narrations = narrations
        self.style = style
        self.createdAt = Date()
    }
}

public enum NarrationStyle: String, Codable, CaseIterable, Sendable, Identifiable {
    case professional, casual, academic, storytelling, minimal

    public var id: String { rawValue }

    public var displayName: String { rawValue.capitalized }
}

public struct SlideTiming: Identifiable, Sendable {
    public let id = UUID()
    public let slideIndex: Int
    public let slideTitle: String
    public let allocatedDuration: TimeInterval
    public let bulletCount: Int
}
