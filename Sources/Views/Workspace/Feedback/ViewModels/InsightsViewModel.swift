import Foundation
import Combine

@MainActor
public final class InsightsViewModel: ObservableObject {
    @Published public var categoryDistribution: [FeedbackCategory: Int] = [:]
    @Published public var statusCounts: [FeedbackStatus: Int] = [:]
    @Published public var trendData: [Date: Int] = [:]

    public init() {}

    public func calculateInsights(from reports: [FeedbackReport]) {
        var catDist: [FeedbackCategory: Int] = [:]
        var statCounts: [FeedbackStatus: Int] = [:]

        for report in reports {
            catDist[report.category, default: 0] += 1
            statCounts[report.status, default: 0] += 1
        }

        self.categoryDistribution = catDist
        self.statusCounts = statCounts
    }
}
