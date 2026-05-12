import Foundation
import Combine

struct LatencySample: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let latencyMs: Double
    let success: Bool
}

@MainActor
final class NetworkProfilerBackend: ObservableObject {
    @Published var samples: [LatencySample] = []
    @Published var isRunning = false
    @Published var targetURL = "https://www.apple.com"
    @Published var intervalSeconds: Double = 5
    @Published var statusMessage = ""

    private var timer: AnyCancellable?

    var averageLatency: Double {
        let successful = samples.filter { $0.success }
        guard !successful.isEmpty else { return 0 }
        return successful.map { $0.latencyMs }.reduce(0, +) / Double(successful.count)
    }

    var jitter: Double {
        let successful = samples.filter { $0.success }.map { $0.latencyMs }
        guard successful.count > 1 else { return 0 }
        let mean = successful.reduce(0, +) / Double(successful.count)
        let variance = successful.map { pow($0 - mean, 2) }.reduce(0, +) / Double(successful.count)
        return sqrt(variance)
    }

    var successRate: Double {
        guard !samples.isEmpty else { return 0 }
        return Double(samples.filter { $0.success }.count) / Double(samples.count) * 100
    }

    var recentSamples: [LatencySample] {
        Array(samples.suffix(30))
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        statusMessage = "Monitoring..."
        timer = Timer.publish(every: intervalSeconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.probe() }
            }
        Task { await probe() }
    }

    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
        statusMessage = "Stopped"
    }

    func clearHistory() {
        samples.removeAll()
    }

    private func probe() async {
        guard let url = URL(string: targetURL) else {
            statusMessage = "Invalid URL"
            return
        }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "HEAD"
        let start = Date()
        do {
            let (_, response) = try await NetworkClient.shared.data(for: request, retries: 0)
            let latency = Date().timeIntervalSince(start) * 1000
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let success = (200...399).contains(code)
            let sample = LatencySample(timestamp: Date(), latencyMs: latency, success: success)
            samples.append(sample)
            statusMessage = String(format: "Last: %.0f ms · %d", latency, code)
        } catch {
            let sample = LatencySample(timestamp: Date(), latencyMs: 0, success: false)
            samples.append(sample)
            statusMessage = "Failed: \(error.localizedDescription)"
        }
        if samples.count > 200 { samples.removeFirst(samples.count - 200) }
    }
}
