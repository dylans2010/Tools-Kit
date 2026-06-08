import Foundation
import Combine

@MainActor
public final class SubmissionsViewModel: ObservableObject {
    @Published public var reports: [FeedbackReport] = []
    @Published public var isLoading = false
    @Published public var filter: FeedbackStatus?

    public init() {}

    public func fetchReports() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await FeedbackService.shared.fetchReports()
            reports = fetched.sorted(by: { $0.updatedAt > $1.updatedAt })
        } catch {
            print("Failed to fetch reports: \(error)")
        }
    }

    public func updateStatus(for report: FeedbackReport, to status: FeedbackStatus) async {
        do {
            try await FeedbackService.shared.updateReportStatus(id: report.id, status: status)
            await fetchReports()
        } catch {
            print("Failed to update status: \(error)")
        }
    }

    public var filteredReports: [FeedbackReport] {
        guard let filter = filter else { return reports }
        return reports.filter { $0.status == filter }
    }
}
