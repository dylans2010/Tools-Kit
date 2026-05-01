import Foundation

struct SyncEvent: Identifiable {
    let id = UUID()
    let objectID: UUID
    let type: String
    let createdAt: Date
}

final class SyncEngine {
    static let shared = SyncEngine()
    private(set) var pendingEvents: [SyncEvent] = []
    private let queue = DispatchQueue(label: "sync.engine.queue", qos: .utility)

    private init() {}

    func enqueue(_ event: SyncEvent) {
        queue.async {
            self.pendingEvents.append(event)
        }
    }

    func reconcile() {
        queue.async {
            self.pendingEvents.removeAll()
        }
    }
}
