import SwiftUI

struct Diag_InternetSpeedView: View {
    @State private var isTesting = false
    @State private var downloadSpeed: Double = 0
    @State private var testProgress: Double = 0
    @State private var testComplete = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Speed Test") {
                VStack(spacing: 16) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse, isActive: isTesting)

                    if testComplete {
                        VStack(spacing: 4) {
                            Text("\(downloadSpeed, specifier: "%.1f")")
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                            Text("Mbps (Download)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if isTesting {
                        VStack(spacing: 8) {
                            ProgressView(value: testProgress)
                                .progressViewStyle(.linear)
                                .tint(.blue)
                            Text("Testing...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Tap below to test download speed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }

            if testComplete {
                Section("Rating") {
                    HStack {
                        Text(speedRating)
                            .font(.headline)
                        Spacer()
                        Image(systemName: speedIcon)
                            .foregroundStyle(speedColor)
                    }
                }
            }

            Section {
                Button {
                    runSpeedTest()
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text(isTesting ? "Testing..." : "Start Speed Test")
                    }
                }
                .disabled(isTesting)
            }

            Section {
                Text("This measures approximate download speed by fetching a test file. Results may vary based on network conditions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Internet Speed")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var speedRating: String {
        if downloadSpeed > 100 { return "Excellent" }
        if downloadSpeed > 50 { return "Very Good" }
        if downloadSpeed > 20 { return "Good" }
        if downloadSpeed > 5 { return "Fair" }
        return "Slow"
    }

    private var speedIcon: String {
        if downloadSpeed > 50 { return "bolt.circle.fill" }
        if downloadSpeed > 20 { return "checkmark.circle.fill" }
        return "exclamationmark.triangle.fill"
    }

    private var speedColor: Color {
        if downloadSpeed > 50 { return .green }
        if downloadSpeed > 20 { return .blue }
        if downloadSpeed > 5 { return .yellow }
        return .red
    }

    private func runSpeedTest() {
        isTesting = true
        testComplete = false
        errorMessage = nil
        testProgress = 0

        let testURL = URL(string: "https://speed.cloudflare.com/__down?bytes=5000000")!
        let startTime = Date()

        let task = URLSession.shared.dataTask(with: testURL) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = error.localizedDescription
                    isTesting = false
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received"
                    isTesting = false
                    return
                }

                let elapsed = Date().timeIntervalSince(startTime)
                let bytesReceived = Double(data.count)
                let bitsPerSecond = (bytesReceived * 8) / elapsed
                downloadSpeed = bitsPerSecond / 1_000_000

                testProgress = 1.0
                testComplete = true
                isTesting = false
            }
        }
        task.resume()

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if testComplete || !isTesting {
                timer.invalidate()
                return
            }
            testProgress = min(testProgress + 0.02, 0.95)
        }
    }
}
