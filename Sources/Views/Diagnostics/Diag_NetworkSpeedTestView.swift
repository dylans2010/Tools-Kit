import SwiftUI

struct Diag_NetworkSpeedTestView: View {
    @State private var downloadSpeed: Double = 0
    @State private var uploadSpeed: Double = 0
    @State private var latency: Double = 0
    @State private var isRunning = false
    @State private var hasRun = false
    @State private var status = "Ready"

    var body: some View {
        Form {
            Section("Network Speed Test") {
                VStack(spacing: 16) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)

                    if hasRun {
                        HStack(spacing: 30) {
                            VStack {
                                Text(String(format: "%.1f", downloadSpeed))
                                    .font(.title.bold().monospacedDigit())
                                    .foregroundStyle(.green)
                                Text("Download Mbps")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            VStack {
                                Text(String(format: "%.0f", latency))
                                    .font(.title.bold().monospacedDigit())
                                    .foregroundStyle(.orange)
                                Text("Ping ms")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Text(status)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            if hasRun {
                Section("Results") {
                    LabeledContent("Download") { Text(String(format: "%.2f Mbps", downloadSpeed)).monospacedDigit() }
                    LabeledContent("Latency") { Text(String(format: "%.0f ms", latency)).monospacedDigit() }
                    LabeledContent("Test Server") { Text("apple.com").font(.caption) }
                }
            }

            Section {
                Button {
                    runSpeedTest()
                } label: {
                    HStack {
                        if isRunning { ProgressView().scaleEffect(0.8) }
                        else { Image(systemName: "play.circle.fill") }
                        Text(isRunning ? "Testing..." : hasRun ? "Run Again" : "Start Speed Test")
                    }
                }
                .disabled(isRunning)
            }
        }
        .navigationTitle("Network Speed")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runSpeedTest() {
        isRunning = true
        status = "Measuring latency..."
        downloadSpeed = 0
        latency = 0

        guard let pingURL = URL(string: "https://www.apple.com/library/test/success.html") else {
            status = "Error: Invalid URL"
            isRunning = false
            return
        }

        let pingStart = CFAbsoluteTimeGetCurrent()
        URLSession.shared.dataTask(with: pingURL) { _, _, error in
            let pingTime = (CFAbsoluteTimeGetCurrent() - pingStart) * 1000

            DispatchQueue.main.async {
                if error != nil {
                    status = "Network error — check connection"
                    isRunning = false
                    hasRun = true
                    return
                }
                latency = pingTime
                status = "Measuring download speed..."
            }

            guard let downloadURL = URL(string: "https://updates.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/English.lproj/Documentation/ReadMe.html") else {
                DispatchQueue.main.async {
                    status = "Download URL error"
                    isRunning = false
                    hasRun = true
                }
                return
            }

            let dlStart = CFAbsoluteTimeGetCurrent()
            URLSession.shared.dataTask(with: downloadURL) { data, _, dlError in
                let dlTime = CFAbsoluteTimeGetCurrent() - dlStart

                DispatchQueue.main.async {
                    if let data = data, dlError == nil, dlTime > 0 {
                        let bytesPerSec = Double(data.count) / dlTime
                        let mbps = bytesPerSec * 8 / 1_000_000
                        downloadSpeed = mbps
                        status = "Test complete"
                    } else {
                        status = "Download test failed"
                    }
                    isRunning = false
                    hasRun = true
                }
            }.resume()
        }.resume()
    }
}
