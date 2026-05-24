import SwiftUI
import Network

struct Diag_NetworkThroughputView: View {
    @State private var isRunning = false
    @State private var downloadSpeed: Double = 0
    @State private var uploadSpeed: Double = 0
    @State private var latency: Double = 0
    @State private var jitter: Double = 0
    @State private var packetLoss: Double = 0
    @State private var history: [(Date, Double, Double)] = []
    @State private var statusText = "Tap Start to begin throughput test"
    @State private var progress: Double = 0
    @State private var testPhase: String = ""

    var body: some View {
        Form {
            Section("Current Results") {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        speedGauge(value: downloadSpeed, label: "Download", color: .blue, icon: "arrow.down.circle.fill")
                        speedGauge(value: uploadSpeed, label: "Upload", color: .green, icon: "arrow.up.circle.fill")
                    }
                    .frame(maxWidth: .infinity)

                    if isRunning {
                        VStack(spacing: 4) {
                            ProgressView(value: progress)
                                .tint(.blue)
                            Text(testPhase)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Latency & Quality") {
                LabeledContent("Latency") {
                    Text(latency > 0 ? String(format: "%.1f ms", latency) : "—")
                        .monospacedDigit()
                }
                LabeledContent("Jitter") {
                    Text(jitter > 0 ? String(format: "%.1f ms", jitter) : "—")
                        .monospacedDigit()
                }
                LabeledContent("Packet Loss") {
                    Text(packetLoss > 0 ? String(format: "%.1f%%", packetLoss) : "0%")
                        .monospacedDigit()
                        .foregroundStyle(packetLoss > 2 ? .red : .green)
                }
            }

            if !history.isEmpty {
                Section("History") {
                    ForEach(history.suffix(10).reversed(), id: \.0) { entry in
                        HStack {
                            Text(entry.0, style: .time)
                                .font(.caption.monospacedDigit())
                            Spacer()
                            Text(String(format: "↓%.1f", entry.1))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.blue)
                            Text(String(format: "↑%.1f", entry.2))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.green)
                            Text("Mbps")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    if isRunning { stopTest() } else { startTest() }
                } label: {
                    HStack {
                        Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                        Text(isRunning ? "Stop Test" : "Start Throughput Test")
                    }
                }

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Network Throughput")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func speedGauge(value: Double, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(CGFloat(value / 100.0), 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5), value: value)
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                    Text(String(format: "%.1f", value))
                        .font(.title3.monospacedDigit().bold())
                    Text("Mbps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 110, height: 110)
            Text(label)
                .font(.caption.weight(.medium))
        }
    }

    private func startTest() {
        isRunning = true
        progress = 0
        statusText = "Testing..."

        Task {
            // Phase 1: Latency test
            testPhase = "Measuring latency..."
            progress = 0.1
            let latencyResults = await measureLatency()
            latency = latencyResults.avg
            jitter = latencyResults.jitter
            packetLoss = latencyResults.loss

            guard isRunning else { return }

            // Phase 2: Download test
            testPhase = "Testing download speed..."
            progress = 0.3
            downloadSpeed = await measureDownloadSpeed()

            guard isRunning else { return }

            // Phase 3: Upload test
            testPhase = "Testing upload speed..."
            progress = 0.7
            uploadSpeed = await measureUploadSpeed()

            progress = 1.0
            testPhase = "Complete"
            statusText = "Test completed at \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))"
            history.append((Date(), downloadSpeed, uploadSpeed))
            isRunning = false
        }
    }

    private func stopTest() {
        isRunning = false
        statusText = "Test stopped"
        testPhase = ""
    }

    private func measureLatency() async -> (avg: Double, jitter: Double, loss: Double) {
        let hosts = ["1.1.1.1", "8.8.8.8", "apple.com"]
        var latencies: [Double] = []
        var failures = 0
        let total = 10

        for i in 0..<total {
            let host = hosts[i % hosts.count]
            let start = CFAbsoluteTimeGetCurrent()
            guard let url = URL(string: "https://\(host)") else {
                failures += 1
                continue
            }
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 3
            do {
                let _ = try await URLSession.shared.data(for: request)
                let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                latencies.append(elapsed)
            } catch {
                failures += 1
            }
        }

        guard !latencies.isEmpty else { return (0, 0, Double(failures) / Double(total) * 100) }

        let avg = latencies.reduce(0, +) / Double(latencies.count)
        var jitterSum = 0.0
        for i in 1..<latencies.count {
            jitterSum += abs(latencies[i] - latencies[i - 1])
        }
        let jitter = latencies.count > 1 ? jitterSum / Double(latencies.count - 1) : 0
        let loss = Double(failures) / Double(total) * 100

        return (avg, jitter, loss)
    }

    private func measureDownloadSpeed() async -> Double {
        let testURLs = [
            "https://speed.cloudflare.com/__down?bytes=10000000",
            "https://proof.ovh.net/files/1Mb.dat",
            "https://ash-speed.hetzner.com/1MB.bin"
        ]

        var bestSpeed = 0.0

        for urlString in testURLs {
            guard let url = URL(string: urlString) else { continue }
            var request = URLRequest(url: url)
            request.timeoutInterval = 15

            let start = CFAbsoluteTimeGetCurrent()
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let elapsed = CFAbsoluteTimeGetCurrent() - start
                guard elapsed > 0 else { continue }
                let speedMbps = (Double(data.count) * 8.0) / (elapsed * 1_000_000.0)
                bestSpeed = max(bestSpeed, speedMbps)
                break
            } catch {
                continue
            }
        }

        return bestSpeed
    }

    private func measureUploadSpeed() async -> Double {
        guard let url = URL(string: "https://speed.cloudflare.com/__up") else { return 0 }

        let payloadSize = 1_000_000
        let payload = Data(repeating: 0x41, count: payloadSize)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = payload
        request.timeoutInterval = 15
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        let start = CFAbsoluteTimeGetCurrent()
        do {
            let _ = try await URLSession.shared.data(for: request)
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            guard elapsed > 0 else { return 0 }
            return (Double(payloadSize) * 8.0) / (elapsed * 1_000_000.0)
        } catch {
            return 0
        }
    }
}
