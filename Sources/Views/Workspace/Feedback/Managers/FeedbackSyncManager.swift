import Foundation
import Network

public final class FeedbackSyncManager {
    public static let shared = FeedbackSyncManager()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.toolskit.sync.manager")
    private var isConnected = true

    private let pendingSubmissionsKey = "com.toolskit.feedback.pending"

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            if self?.isConnected == true {
                self?.processPendingQueue()
            }
        }
        monitor.start(queue: queue)
    }

    public func queueForSubmission(_ report: FeedbackReport) {
        var pending = getPendingReports()
        pending.append(report)
        savePendingReports(pending)

        if isConnected {
            processPendingQueue()
        }
    }

    private func processPendingQueue() {
        let pending = getPendingReports()
        guard !pending.isEmpty else { return }

        Task {
            for report in pending {
                do {
                    _ = try await FeedbackService.shared.submitReport(report)
                    self.removeFromQueue(report.id)
                } catch {
                    print("Sync failed for \(report.id): \(error.localizedDescription)")
                }
            }
        }
    }

    private func removeFromQueue(_ id: UUID) {
        var pending = getPendingReports()
        pending.removeAll { $0.id == id }
        savePendingReports(pending)
    }

    private func getPendingReports() -> [FeedbackReport] {
        guard let data = UserDefaults.standard.data(forKey: pendingSubmissionsKey),
              let reports = try? JSONDecoder().decode([FeedbackReport].self, from: data) else {
            return []
        }
        return reports
    }

    private func savePendingReports(_ reports: [FeedbackReport]) {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: pendingSubmissionsKey)
        }
    }
}
