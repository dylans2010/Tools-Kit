import Foundation
import Combine

@MainActor
public final class SubmissionsViewModel: ObservableObject {
    @Published public var reports: [FeedbackReport] = []
    @Published public var isLoading = false
    @Published public var filter: FeedbackStatus?
    @Published public var searchText = ""
    @Published public var sortOrder: SortOption = .date

    public enum SortOption: String, CaseIterable, Identifiable {
        case date, priority, status
        public var id: String { rawValue }
        public var displayName: String { rawValue.capitalized }
    }

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
        var result = reports

        if let filter = filter {
            result = result.filter { $0.status == filter }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.summary.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .date:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .priority:
            result.sort { $0.priority > $1.priority }
        case .status:
            result.sort { $0.status < $1.status }
        }

        return result
    }
}
