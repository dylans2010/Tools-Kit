import SwiftUI
import Network

struct Diag_PingToolView: View {
    @State private var host: String = "8.8.8.8"
    @State private var results: [PingResult] = []
    @State private var isPinging = false
    @State private var pingCount: Int = 0
    @State private var maxPings: Int = 10
    @State private var stats: PingStats?

    struct PingResult: Identifiable {
        let id = UUID()
        let sequence: Int
        let time: TimeInterval
        let success: Bool
        let timestamp: Date
    }

    struct PingStats {
        let sent: Int
        let received: Int
        let lost: Int
        let minTime: TimeInterval
        let maxTime: TimeInterval
        let avgTime: TimeInterval
        var lossPercent: Double { sent > 0 ? Double(lost) / Double(sent) * 100 : 0 }
    }

    var body: some View {
        Form {
            Section("Target") {
                HStack {
                    TextField("Host or IP", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Button {
                        if isPinging { stopPing() } else { startPing() }
                    } label: {
                        Image(systemName: isPinging ? "stop.fill" : "play.fill")
                    }
                    .disabled(host.isEmpty)
                }

                Picker("Count", selection: $maxPings) {
                    Text("5").tag(5)
                    Text("10").tag(10)
                    Text("20").tag(20)
                    Text("50").tag(50)
                }
                .pickerStyle(.segmented)
            }

            if let stats = stats {
                Section("Statistics") {
                    LabeledContent("Sent") { Text("\(stats.sent)") }
                    LabeledContent("Received") { Text("\(stats.received)").foregroundStyle(.green) }
                    LabeledContent("Lost") {
                        Text("\(stats.lost) (\(String(format: "%.1f%%", stats.lossPercent)))")
                            .foregroundStyle(stats.lost > 0 ? .red : .green)
                    }
                    LabeledContent("Min") { Text(String(format: "%.1f ms", stats.minTime * 1000)).monospacedDigit() }
                    LabeledContent("Avg") { Text(String(format: "%.1f ms", stats.avgTime * 1000)).monospacedDigit() }
                    LabeledContent("Max") { Text(String(format: "%.1f ms", stats.maxTime * 1000)).monospacedDigit() }
                }
            }

            if isPinging {
                Section {
                    HStack {
                        ProgressView()
                        Text("Pinging \(host)... (\(pingCount)/\(maxPings))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !results.isEmpty {
                Section("Results") {
                    ForEach(results, id: \.id) { result in
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.success ? .green : .red)
                                .font(.caption)
                            Text("#\(result.sequence)")
                                .font(.caption.monospacedDigit())
                                .frame(width: 30, alignment: .leading)
                            Spacer()
                            if result.success {
                                Text(String(format: "%.1f ms", result.time * 1000))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(pingTimeColor(result.time))
                            } else {
                                Text("Timeout")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }

            Section("Presets") {
                ForEach([
                    ("8.8.8.8", "Google DNS"),
                    ("1.1.1.1", "Cloudflare DNS"),
                    ("208.67.222.222", "OpenDNS"),
                    ("apple.com", "Apple"),
                ], id: \.0) { ip, name in
                    Button {
                        host = ip
                    } label: {
                        HStack {
                            Text(name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(ip)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Ping Tool")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pingTimeColor(_ time: TimeInterval) -> Color {
        let ms = time * 1000
        if ms < 50 { return .green }
        if ms < 150 { return .orange }
        return .red
    }

    private func startPing() {
        isPinging = true
        results = []
        pingCount = 0
        stats = nil

        DispatchQueue.global(qos: .userInitiated).async {
            for seq in 1...maxPings {
                guard isPinging else { break }
                DispatchQueue.main.async { pingCount = seq }

                let start = CFAbsoluteTimeGetCurrent()
                let success = performPing(host: host)
                let elapsed = CFAbsoluteTimeGetCurrent() - start

                let result = PingResult(sequence: seq, time: success ? elapsed : 0, success: success, timestamp: Date())
                DispatchQueue.main.async { results.append(result) }

                Thread.sleep(forTimeInterval: 1.0)
            }

            DispatchQueue.main.async {
                isPinging = false
                calculateStats()
            }
        }
    }

    private func stopPing() {
        isPinging = false
        calculateStats()
    }

    private func calculateStats() {
        let successful = results.filter(\.success)
        let times = successful.map(\.time)
        stats = PingStats(
            sent: results.count,
            received: successful.count,
            lost: results.count - successful.count,
            minTime: times.min() ?? 0,
            maxTime: times.max() ?? 0,
            avgTime: times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
        )
    }

    private func performPing(host: String) -> Bool {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: 80, using: .tcp)
        let semaphore = DispatchSemaphore(value: 0)
        var success = false

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                success = true
                connection.cancel()
                semaphore.signal()
            case .failed, .cancelled:
                semaphore.signal()
            default:
                break
            }
        }
        connection.start(queue: .global(qos: .userInitiated))
        _ = semaphore.wait(timeout: .now() + 3)
        if connection.state != .cancelled { connection.cancel() }
        return success
    }
}
