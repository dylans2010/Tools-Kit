import Foundation
import Combine

final class SyncEngine: ObservableObject {
    static let shared = SyncEngine()
    @Published var isOnline = true
    @Published var lastSyncDate: Date?
    private init() {}
    func enqueue(_ op: @escaping () async throws -> Void) {
        Task { try? await op(); await MainActor.run { self.lastSyncDate = Date() } }
    }
}