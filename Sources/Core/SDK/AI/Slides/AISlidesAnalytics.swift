import Foundation
import Combine

@MainActor
public final class AISlidesAnalytics: ObservableObject {
    public static let shared = AISlidesAnalytics()

    @Published public private(set) var presentationStats: [UUID: PresentationStats] = [:]
    @Published public private(set) var generationMetrics: [GenerationMetric] = []
    @Published public private(set) var slideEngagement: [UUID: SlideEngagementData] = [:]

    private init() {}

    // MARK: - Presentation Tracking

    public func startPresentation(deckID: UUID, slideCount: Int) {
        presentationStats[deckID] = PresentationStats(deckID: deckID, totalSlides: slideCount)
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "slides.analytics",
            name: "presentation.started",
            data: ["deck": deckID.uuidString, "slides": "\(slideCount)"]
        ))
    }

    public func recordSlideView(deckID: UUID, slideIndex: Int, duration: TimeInterval) {
        guard presentationStats[deckID] != nil else { return }
        let view = SlideView(slideIndex: slideIndex, duration: duration)
        presentationStats[deckID]?.slideViews.append(view)

        let slideID = UUID(uuidString: "\(deckID)-\(slideIndex)") ?? UUID()
        if slideEngagement[slideID] == nil {
            slideEngagement[slideID] = SlideEngagementData(slideIndex: slideIndex)
        }
        slideEngagement[slideID]?.viewCount += 1
        slideEngagement[slideID]?.totalDuration += duration
    }

    public func endPresentation(deckID: UUID) {
        presentationStats[deckID]?.endedAt = Date()
        let stats = presentationStats[deckID]
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "slides.analytics",
            name: "presentation.ended",
            data: [
                "deck": deckID.uuidString,
                "duration": "\(stats?.totalDuration ?? 0)",
                "slides_viewed": "\(stats?.uniqueSlidesViewed ?? 0)"
            ]
        ))
    }

    // MARK: - Generation Metrics

    public func recordGeneration(input: String, slideCount: Int, duration: TimeInterval, modelUsed: String, success: Bool) {
        let metric = GenerationMetric(
            prompt: input,
            slideCount: slideCount,
            duration: duration,
            modelUsed: modelUsed,
            success: success
        )
        generationMetrics.append(metric)
    }

    // MARK: - Aggregate Stats

    public var averageGenerationTime: TimeInterval {
        let successful = generationMetrics.filter(\.success)
        guard !successful.isEmpty else { return 0 }
        return successful.reduce(0) { $0 + $1.duration } / Double(successful.count)
    }

    public var generationSuccessRate: Double {
        guard !generationMetrics.isEmpty else { return 0 }
        return Double(generationMetrics.count(where: \.success)) / Double(generationMetrics.count)
    }

    public var averageSlidesPerDeck: Double {
        let successful = generationMetrics.filter(\.success)
        guard !successful.isEmpty else { return 0 }
        return Double(successful.reduce(0) { $0 + $1.slideCount }) / Double(successful.count)
    }

    public var totalPresentations: Int {
        presentationStats.count
    }

    public var averagePresentationDuration: TimeInterval {
        let completed = presentationStats.values.filter { $0.endedAt != nil }
        guard !completed.isEmpty else { return 0 }
        return completed.reduce(0) { $0 + $1.totalDuration } / Double(completed.count)
    }

    // MARK: - Most Viewed Slides

    public func topSlides(deckID: UUID, limit: Int = 5) -> [SlideView] {
        guard let stats = presentationStats[deckID] else { return [] }
        let grouped = Dictionary(grouping: stats.slideViews, by: \.slideIndex)
        return grouped.map { index, views in
            SlideView(slideIndex: index, duration: views.reduce(0) { $0 + $1.duration })
        }
        .sorted { $0.duration > $1.duration }
        .prefix(limit)
        .map { $0 }
    }

    // MARK: - Reset

    public func reset() {
        presentationStats.removeAll()
        generationMetrics.removeAll()
        slideEngagement.removeAll()
    }
}

// MARK: - Models

public struct PresentationStats: Identifiable {
    public let id: UUID
    public let deckID: UUID
    public let totalSlides: Int
    public let startedAt: Date
    public var endedAt: Date?
    public var slideViews: [SlideView]

    public var totalDuration: TimeInterval {
        guard let end = endedAt else {
            return Date().timeIntervalSince(startedAt)
        }
        return end.timeIntervalSince(startedAt)
    }

    public var uniqueSlidesViewed: Int {
        Set(slideViews.map(\.slideIndex)).count
    }

    public var completionRate: Double {
        guard totalSlides > 0 else { return 0 }
        return Double(uniqueSlidesViewed) / Double(totalSlides)
    }

    public init(deckID: UUID, totalSlides: Int) {
        self.id = UUID()
        self.deckID = deckID
        self.totalSlides = totalSlides
        self.startedAt = Date()
        self.slideViews = []
    }
}

public struct SlideView: Identifiable {
    public let id = UUID()
    public let slideIndex: Int
    public let duration: TimeInterval
    public let viewedAt: Date

    public init(slideIndex: Int, duration: TimeInterval) {
        self.slideIndex = slideIndex
        self.duration = duration
        self.viewedAt = Date()
    }
}

public struct GenerationMetric: Identifiable {
    public let id = UUID()
    public let prompt: String
    public let slideCount: Int
    public let duration: TimeInterval
    public let modelUsed: String
    public let success: Bool
    public let timestamp: Date

    public init(prompt: String, slideCount: Int, duration: TimeInterval, modelUsed: String, success: Bool) {
        self.prompt = prompt
        self.slideCount = slideCount
        self.duration = duration
        self.modelUsed = modelUsed
        self.success = success
        self.timestamp = Date()
    }
}

public struct SlideEngagementData: Identifiable {
    public let id = UUID()
    public let slideIndex: Int
    public var viewCount: Int
    public var totalDuration: TimeInterval

    public var averageDuration: TimeInterval {
        viewCount > 0 ? totalDuration / Double(viewCount) : 0
    }

    public init(slideIndex: Int) {
        self.slideIndex = slideIndex
        self.viewCount = 0
        self.totalDuration = 0
    }
}
