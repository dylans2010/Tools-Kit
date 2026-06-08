import Foundation
import Combine

@MainActor
public final class FeedbackMainViewModel: ObservableObject {
    @Published public var recentActivity: [FeedbackActivity] = []
    @Published public var news: [FeedbackNews] = []
    @Published public var requests: [FeedbackRequest] = []
    @Published public var drafts: [FeedbackReport] = []
    @Published public var isLoading = false

    public init() {}

    public func refresh() async {
        isLoading = true
        defer { isLoading = false }

        // Fetch news and requests from service
        news = await FeedbackService.shared.fetchNews()
        requests = await FeedbackService.shared.fetchRequests()

        // Fetch submissions to populate activity and drafts
        if let reports = try? await FeedbackService.shared.fetchReports() {
            recentActivity = reports.flatMap { $0.history }.sorted(by: { $0.timestamp > $1.timestamp }).prefix(10).map { $0 }
            drafts = reports.filter { $0.status == .draft }.sorted(by: { $0.updatedAt > $1.updatedAt })
        }
    }
}
