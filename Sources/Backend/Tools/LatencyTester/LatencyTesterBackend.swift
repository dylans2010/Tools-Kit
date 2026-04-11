import Foundation

struct LatencyResult: Identifiable {
    let id = UUID()
    let index: Int
    let timestamp: Date
    let latencyMs: Double?
    let status: String
}

class LatencyTesterBackend: ObservableObject {
    @Published var host: String = "google.com"
    @Published var results: [LatencyResult] = []
    @Published var isRunning: Bool = false
    @Published var averageLatency: Double = 0.0

    private var stopRequested = false
    private var currentTask: Task<Void, Never>?

    func start(count: Int) {
        guard !isRunning else { return }
        results = []
        averageLatency = 0.0
        stopRequested = false
        isRunning = true

        currentTask = Task { [weak self] in
            guard let self = self else { return }
            for i in 1...max(1, count) {
                if self.stopRequested { break }
                let result = await self.ping(index: i)
                await MainActor.run {
                    self.results.append(result)
                    self.updateAverage()
                }
                if i < count && !self.stopRequested {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
            await MainActor.run { self.isRunning = false }
        }
    }

    func stop() {
        stopRequested = true
        currentTask?.cancel()
    }

    private func ping(index: Int) async -> LatencyResult {
        let urlString = host.hasPrefix("http") ? host : "https://\(host)"
        guard let url = URL(string: urlString) else {
            return LatencyResult(index: index, timestamp: Date(), latencyMs: nil, status: "Invalid URL")
        }

        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = "HEAD"

        let start = Date()
        do {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 5
            let session = URLSession(configuration: config)
            let (_, response) = try await session.data(for: request)
            let elapsed = Date().timeIntervalSince(start) * 1000
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            return LatencyResult(index: index, timestamp: Date(), latencyMs: elapsed, status: "HTTP \(code)")
        } catch {
            let elapsed = Date().timeIntervalSince(start) * 1000
            return LatencyResult(index: index, timestamp: Date(), latencyMs: elapsed, status: "Error: \(error.localizedDescription)")
        }
    }

    private func updateAverage() {
        let values = results.compactMap { $0.latencyMs }
        guard !values.isEmpty else { return }
        averageLatency = values.reduce(0, +) / Double(values.count)
    }
}
