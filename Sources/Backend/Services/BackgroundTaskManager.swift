import Foundation
import Combine

final class BackgroundTaskManager {
    nonisolated(unsafe) static let shared = BackgroundTaskManager()

    private var tasks: [String: Task<Void, Never>] = [:]
    private var timers: [String: AnyCancellable] = [:]

    private init() {}

    func schedule(identifier: String, interval: TimeInterval, work: @escaping () async -> Void) {
        cancel(identifier: identifier)
        let timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task { await work() }
            }
        timers[identifier] = timer
        Task { await work() }
    }

    func cancel(identifier: String) {
        timers[identifier]?.cancel()
        timers.removeValue(forKey: identifier)
        tasks[identifier]?.cancel()
        tasks.removeValue(forKey: identifier)
    }

    func cancelAll() {
        timers.values.forEach { $0.cancel() }
        timers.removeAll()
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
