import SwiftUI

struct Diag_NetworkLatencyView: View {
    @State private var isPinging = false
    @State private var results: [PingResult] = []
    @State private var targetHost = "apple.com"

    private let hosts = ["apple.com", "google.com", "cloudflare.com", "github.com"]

    var body: some View {
        Form {
            Section("Target") {
                Picker("Host", selection: $targetHost) {
                    ForEach(hosts, id: \.self) { host in
                        Text(host).tag(host)
                    }
                }
            }

            Section("Ping Results") {
                if results.isEmpty {
                    Text("No results yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(results) { result in
                        HStack {
                            Circle()
                                .fill(result.success ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(result.host)
                                .font(.subheadline)
                            Spacer()
                            if result.success {
                                Text("\(result.latencyMs, specifier: "%.0f") ms")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(latencyColor(result.latencyMs))
                            } else {
                                Text("Failed")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }

            if !results.isEmpty {
                let successful = results.filter { $0.success }
                if !successful.isEmpty {
                    Section("Statistics") {
                        let latencies = successful.map { $0.latencyMs }
                        LabeledContent("Average") {
                            Text("\(latencies.reduce(0, +) / Double(latencies.count), specifier: "%.0f") ms")
                                .monospacedDigit()
                        }
                        LabeledContent("Min") {
                            Text("\(latencies.min() ?? 0, specifier: "%.0f") ms")
                                .monospacedDigit()
                        }
                        LabeledContent("Max") {
                            Text("\(latencies.max() ?? 0, specifier: "%.0f") ms")
                                .monospacedDigit()
                        }
                        LabeledContent("Success Rate") {
                            Text("\(Int(Double(successful.count) / Double(results.count) * 100))%")
                        }
                    }
                }
            }

            Section {
                Button {
                    runPing()
                } label: {
                    HStack {
                        Image(systemName: "network")
                        Text(isPinging ? "Pinging..." : "Run Ping Test")
                    }
                }
                .disabled(isPinging)

                if !results.isEmpty {
                    Button("Clear Results", role: .destructive) {
                        results.removeAll()
                    }
                }
            }
        }
        .navigationTitle("Network Latency")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func latencyColor(_ ms: Double) -> Color {
        if ms < 50 { return .green }
        if ms < 150 { return .yellow }
        return .red
    }

    private func runPing() {
        isPinging = true
        let host = targetHost
        Task {
            for _ in 0..<5 {
                let start = Date()
                let url = URL(string: "https://\(host)")!
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 5

                do {
                    let (_, response) = try await URLSession.shared.data(for: request)
                    let latency = Date().timeIntervalSince(start) * 1000
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    await MainActor.run {
                        results.append(PingResult(host: host, latencyMs: latency, success: statusCode > 0))
                    }
                } catch {
                    await MainActor.run {
                        results.append(PingResult(host: host, latencyMs: 0, success: false))
                    }
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            await MainActor.run { isPinging = false }
        }
    }
}

