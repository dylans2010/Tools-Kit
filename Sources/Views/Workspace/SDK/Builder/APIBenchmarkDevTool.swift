import SwiftUI

struct APIBenchmarkDevTool: DevTool {
    let id = "api-benchmark"
    let name = "API Benchmark"
    let category: DevToolCategory = .performance
    let icon = "stopwatch"
    let description = "Benchmark API response times"

    @State private var urlString = "https://google.com"
    @State private var results = ""
    @State private var isRunning = false

    func render() -> some View {
        VStack {
            TextField("URL", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Button(isRunning ? "Benchmarking..." : "Run Benchmark (5 requests)") {
                runBenchmark()
            }
            .disabled(isRunning || urlString.isEmpty)
            .padding()

            ScrollView {
                Text(results)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }

    private func runBenchmark() {
        guard let url = URL(string: urlString) else {
            results = "Invalid URL"
            return
        }

        isRunning = true
        results = "Starting benchmark for \(urlString)...\n"

        Task {
            var totalTime: TimeInterval = 0
            for i in 1...5 {
                let start = Date()
                do {
                    let (_, _) = try await URLSession.shared.data(from: url)
                    let duration = Date().timeIntervalSince(start)
                    totalTime += duration
                    await MainActor.run {
                        results += "Request \(i): \(String(format: "%.3f", duration))s\n"
                    }
                } catch {
                    await MainActor.run {
                        results += "Request \(i): Failed - \(error.localizedDescription)\n"
                    }
                }
            }
            let avg = totalTime / 5
            await MainActor.run {
                results += "\nAverage Latency: \(String(format: "%.3f", avg))s"
                isRunning = false
            }
        }
    }
}
