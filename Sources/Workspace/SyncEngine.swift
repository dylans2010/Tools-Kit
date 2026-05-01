import Foundation
import Combine
final class SyncEngine: ObservableObject {
    static let shared = SyncEngine()
    @Published var isOnline = true
    private init() {}
    func enqueue(_ op: @escaping () async throws -> Void) { Task { try? await op() } }
}