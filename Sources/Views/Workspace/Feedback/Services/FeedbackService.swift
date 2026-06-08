import Foundation
import CryptoKit

public final class FeedbackService {
    public static let shared = FeedbackService()

    private let session = URLSession.shared
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    private init() {
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonDecoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Submission & Lifecycle

    public func submitReport(_ report: FeedbackReport) async throws -> FeedbackReport {
        // In a real implementation, this would send to an API.
        // Here we simulate the network and server processing.

        var submittedReport = report
        submittedReport.status = .submitted
        submittedReport.updatedAt = Date()
        submittedReport.history.append(FeedbackActivity(
            id: UUID(),
            timestamp: Date(),
            action: "Report submitted",
            actor: "User"
        ))

        // E2E Encryption before transfer
        let encryptedPayload = try encryptReport(submittedReport)

        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Save locally for now as mock persistence
        saveReportLocally(submittedReport)

        return submittedReport
    }

    public func fetchReports() async throws -> [FeedbackReport] {
        // Return locally stored reports
        return getLocalReports()
    }

    public func updateReportStatus(id: UUID, status: FeedbackStatus) async throws {
        var reports = getLocalReports()
        if let index = reports.firstIndex(where: { $0.id == id }) {
            reports[index].status = status
            reports[index].updatedAt = Date()
            reports[index].history.append(FeedbackActivity(
                id: UUID(),
                timestamp: Date(),
                action: "Status updated to \(status.displayName)",
                actor: "System"
            ))
            saveAllReports(reports)
        }
    }

    // MARK: - Encryption

    private func encryptReport(_ report: FeedbackReport) throws -> Data {
        let data = try jsonEncoder.encode(report)
        // Simple E2EE mock using SymmetricKey
        let key = SymmetricKey(size: .bits256) // In production, this comes from a secure key management service
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    // MARK: - Local Persistence (Mocking Backend)

    private let reportsKey = "com.toolskit.feedback.reports"

    private func saveReportLocally(_ report: FeedbackReport) {
        var reports = getLocalReports()
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = report
        } else {
            reports.append(report)
        }
        saveAllReports(reports)
    }

    private func getLocalReports() -> [FeedbackReport] {
        guard let data = UserDefaults.standard.data(forKey: reportsKey),
              let reports = try? jsonDecoder.decode([FeedbackReport].self, from: data) else {
            return []
        }
        return reports
    }

    private func saveAllReports(_ reports: [FeedbackReport]) {
        if let data = try? jsonEncoder.encode(reports) {
            UserDefaults.standard.set(data, forKey: reportsKey)
        }
    }

    // MARK: - Mock Data for Dashboard

    public func fetchNews() async -> [FeedbackNews] {
        return [
            FeedbackNews(id: UUID(), title: "System Update v1.2", body: "We've improved the AI response time significantly.", date: Date().addingTimeInterval(-86400), type: .update),
            FeedbackNews(id: UUID(), title: "Performance Fixes", body: "Fixed a memory leak in the dashboard.", date: Date().addingTimeInterval(-172800), type: .fix)
        ]
    }

    public func fetchRequests() async -> [FeedbackRequest] {
        return [
            FeedbackRequest(id: UUID(), title: "Dark Mode for Music", description: "Allow users to toggle dark mode specifically for the music player.", votes: 42, hasVoted: false, category: .music, status: "Planned"),
            FeedbackRequest(id: UUID(), title: "Offline AI Chat", description: "Support for basic local models when offline.", votes: 156, hasVoted: true, category: .aiChat, status: "Under Review")
        ]
    }
}
