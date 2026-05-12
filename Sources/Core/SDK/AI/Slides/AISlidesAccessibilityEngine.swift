import Foundation
import Combine

@MainActor
public final class AISlidesAccessibilityEngine: ObservableObject {
    nonisolated(unsafe) public static let shared = AISlidesAccessibilityEngine()

    @Published public private(set) var lastAudit: SlideAccessibilityReport?
    @Published public private(set) var auditHistory: [SlideAccessibilityReport] = []

    private init() {}

    // MARK: - Audit

    public func audit(deck: SlideDeck) -> SlideAccessibilityReport {
        var issues: [SlideAccessibilityIssue] = []

        for (index, slide) in deck.slides.enumerated() {
            issues.append(contentsOf: auditSlide(slide, index: index))
        }

        issues.append(contentsOf: auditDeckLevel(deck))

        let report = SlideAccessibilityReport(
            deckID: deck.id,
            deckTitle: deck.title,
            slideCount: deck.slides.count,
            issues: issues
        )

        lastAudit = report
        auditHistory.append(report)

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "slides.accessibility",
            name: "audit.completed",
            data: [
                "deck": deck.id.uuidString,
                "issues": "\(issues.count)",
                "score": "\(report.score)"
            ]
        ))

        return report
    }

    // MARK: - Suggestions

    public func suggestFixes(for report: SlideAccessibilityReport) -> [AccessibilityFix] {
        report.issues.map { issue in
            AccessibilityFix(
                issueID: issue.id,
                slideIndex: issue.slideIndex,
                description: issue.suggestion,
                priority: issue.severity == .critical ? .high : issue.severity == .warning ? .medium : .low,
                automated: issue.rule == .missingAltText || issue.rule == .emptySlide
            )
        }
    }

    // MARK: - Private Audit Logic

    private func auditSlide(_ slide: Slide, index: Int) -> [SlideAccessibilityIssue] {
        var issues: [SlideAccessibilityIssue] = []

        if slide.title.isEmpty {
            issues.append(SlideAccessibilityIssue(
                slideIndex: index,
                rule: .missingTitle,
                severity: .critical,
                message: "Slide \(index + 1) has no title",
                suggestion: "Add a descriptive title for screen reader navigation"
            ))
        }

        if slide.bullets.isEmpty {
            issues.append(SlideAccessibilityIssue(
                slideIndex: index,
                rule: .emptySlide,
                severity: .warning,
                message: "Slide \(index + 1) has no content bullets",
                suggestion: "Add content or mark as a visual/decorative slide"
            ))
        }

        if slide.title.count > 80 {
            issues.append(SlideAccessibilityIssue(
                slideIndex: index,
                rule: .titleTooLong,
                severity: .info,
                message: "Slide \(index + 1) title exceeds 80 characters",
                suggestion: "Shorten the title for better readability"
            ))
        }

        if slide.bullets.count > 7 {
            issues.append(SlideAccessibilityIssue(
                slideIndex: index,
                rule: .tooManyBullets,
                severity: .warning,
                message: "Slide \(index + 1) has \(slide.bullets.count) bullet points",
                suggestion: "Limit to 5-7 bullets per slide for cognitive accessibility"
            ))
        }

        for (bulletIndex, bullet) in slide.bullets.enumerated() {
            if bullet.count > 120 {
                issues.append(SlideAccessibilityIssue(
                    slideIndex: index,
                    rule: .bulletTooLong,
                    severity: .info,
                    message: "Slide \(index + 1), bullet \(bulletIndex + 1) exceeds 120 characters",
                    suggestion: "Break long text into shorter phrases"
                ))
            }
        }

        let words = slide.bullets.joined(separator: " ").split(separator: " ").count
        let readingTime = Double(words) / 200 * 60
        if readingTime > 45 {
            issues.append(SlideAccessibilityIssue(
                slideIndex: index,
                rule: .tooMuchText,
                severity: .warning,
                message: "Slide \(index + 1) has ~\(words) words (>\(Int(readingTime))s reading time)",
                suggestion: "Reduce text content for better comprehension"
            ))
        }

        return issues
    }

    private func auditDeckLevel(_ deck: SlideDeck) -> [SlideAccessibilityIssue] {
        var issues: [SlideAccessibilityIssue] = []

        if deck.slides.count > 30 {
            issues.append(SlideAccessibilityIssue(
                slideIndex: -1,
                rule: .deckTooLong,
                severity: .info,
                message: "Deck has \(deck.slides.count) slides",
                suggestion: "Consider breaking into multiple presentations for accessibility"
            ))
        }

        let titlesWithNotes = deck.slides.count(where: { $0.speakerNotes != nil && !($0.speakerNotes?.isEmpty ?? true) })
        if titlesWithNotes == 0 && deck.slides.count > 3 {
            issues.append(SlideAccessibilityIssue(
                slideIndex: -1,
                rule: .noSpeakerNotes,
                severity: .warning,
                message: "No slides have speaker notes",
                suggestion: "Add speaker notes for users who need text alternatives"
            ))
        }

        let duplicateTitles = Dictionary(grouping: deck.slides, by: \.title).filter { $0.value.count > 1 }
        for (title, _) in duplicateTitles {
            issues.append(SlideAccessibilityIssue(
                slideIndex: -1,
                rule: .duplicateTitle,
                severity: .info,
                message: "Duplicate slide title: \"\(title)\"",
                suggestion: "Use unique titles for better navigation with assistive technology"
            ))
        }

        return issues
    }
}

// MARK: - Models

public struct SlideAccessibilityReport: Identifiable, Sendable {
    public let id: UUID
    public let deckID: UUID
    public let deckTitle: String
    public let slideCount: Int
    public let issues: [SlideAccessibilityIssue]
    public let auditedAt: Date

    public var score: Int {
        let criticalPenalty = issues.count(where: { $0.severity == .critical }) * 25
        let warningPenalty = issues.count(where: { $0.severity == .warning }) * 10
        let infoPenalty = issues.count(where: { $0.severity == .info }) * 3
        return max(0, 100 - criticalPenalty - warningPenalty - infoPenalty)
    }

    public var criticalCount: Int { issues.count(where: { $0.severity == .critical }) }
    public var warningCount: Int { issues.count(where: { $0.severity == .warning }) }
    public var infoCount: Int { issues.count(where: { $0.severity == .info }) }

    public init(deckID: UUID, deckTitle: String, slideCount: Int, issues: [SlideAccessibilityIssue]) {
        self.id = UUID()
        self.deckID = deckID
        self.deckTitle = deckTitle
        self.slideCount = slideCount
        self.issues = issues
        self.auditedAt = Date()
    }
}

public struct SlideAccessibilityIssue: Identifiable, Sendable {
    public let id = UUID()
    public let slideIndex: Int
    public let rule: AccessibilityRule
    public let severity: SlideIssueSeverity
    public let message: String
    public let suggestion: String
}

public enum AccessibilityRule: String, Codable, CaseIterable, Sendable {
    case missingTitle
    case emptySlide
    case titleTooLong
    case tooManyBullets
    case bulletTooLong
    case tooMuchText
    case missingAltText
    case deckTooLong
    case noSpeakerNotes
    case duplicateTitle
}

public enum SlideIssueSeverity: String, Codable, Sendable {
    case critical, warning, info
}

public struct AccessibilityFix: Identifiable, Sendable {
    public let id = UUID()
    public let issueID: UUID
    public let slideIndex: Int
    public let description: String
    public let priority: FixPriority
    public let automated: Bool
}

public enum FixPriority: String, Codable, Sendable {
    case high, medium, low
}
