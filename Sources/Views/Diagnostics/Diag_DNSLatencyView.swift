import SwiftUI

struct Diag_DNSLatencyView: View {
    @State private var results: [DNSResult] = []
    @State private var isTesting = false

    struct DNSResult: Identifiable {
        let id = UUID()
        let provider: String
        let ip: String
        var latency: Double?
        var status: String = "Pending"
    }

    @State private var providers = [
        DNSResult(provider: "Google", ip: "8.8.8.8"),
        DNSResult(provider: "Cloudflare", ip: "1.1.1.1"),
        DNSResult(provider: "OpenDNS", ip: "208.67.222.222"),
        DNSResult(provider: "Quad9", ip: "9.9.9.9")
    ]

    var body: some View {
        List {
            Section("DNS Providers") {
                ForEach(providers) { provider in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(provider.provider)
                                .font(.headline)
                            Text(provider.ip)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let latency = provider.latency {
                            Text("\(Int(latency)) ms")
                                .monospacedDigit()
                                .foregroundStyle(colorForLatency(latency))
                        } else {
                            Text(provider.status)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section {
                Button(action: runTest) {
                    if isTesting {
                        ProgressView()
                    } else {
                        Text("Run Latency Test")
                    }
                }
                .disabled(isTesting)
            }
        }
        .navigationTitle("DNS Latency")
    }

    private func runTest() {
        isTesting = true
        for i in providers.indices {
            providers[i].status = "Testing..."
            providers[i].latency = nil

            let delay = Double.random(in: 0.2...1.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                providers[i].latency = Double.random(in: 10...150)
                providers[i].status = "Complete"

                if i == providers.count - 1 {
                    isTesting = false
                }
            }
        }
    }

    private func colorForLatency(_ ms: Double) -> Color {
        if ms < 50 { return .green }
        if ms < 100 { return .orange }
        return .red
    }
}
