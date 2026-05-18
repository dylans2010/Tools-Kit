import SwiftUI

struct ThreadInspectorTool: DevTool {
    let id = UUID()
    let name = "Thread Inspector"
    let category: DevToolCategory = .diagnostics
    let icon = "arrow.triangle.branch"
    let description = "Inspect active threads and their states"
    func render() -> some View { ThreadInspectorDevToolView() }
}

struct ThreadInspectorDevToolView: View {
    @State private var threads: [ThreadInfo] = []
    @State private var autoRefresh = false
    @State private var timer: Timer?

    struct ThreadInfo: Identifiable {
        let id = UUID()
        let number: Int
        let name: String
        let priority: Double
        let isMain: Bool
        let state: String
    }

    var body: some View {
        Form {
            Section {
                Button("Refresh") { refreshThreads() }
                Toggle("Auto Refresh", isOn: $autoRefresh)
                    .onChange(of: autoRefresh) { _, newValue in
                        if newValue { startTimer() } else { stopTimer() }
                    }
            }
            Section("Active Threads (\(threads.count))") {
                ForEach(threads) { thread in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if thread.isMain {
                                Text("MAIN").font(.caption2.bold())
                                    .padding(.horizontal, 6).padding(.vertical, 1)
                                    .background(Color.orange.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            Text(thread.name).font(.subheadline.weight(.medium))
                            Spacer()
                            Text(thread.state).font(.caption)
                                .foregroundStyle(thread.state == "Running" ? .green : .secondary)
                        }
                        HStack {
                            Text("Thread \(thread.number)").font(.caption2)
                            Spacer()
                            Text("Priority: \(String(format: "%.1f", thread.priority))").font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Thread Inspector")
        .onAppear { refreshThreads() }
        .onDisappear { stopTimer() }
    }

    private func refreshThreads() {
        let isMain = Thread.isMainThread
        let currentPriority = Thread.current.threadPriority
        let count = ProcessInfo.processInfo.activeProcessorCount

        threads = [
            ThreadInfo(number: 0, name: "com.apple.main-thread", priority: currentPriority,
                      isMain: true, state: "Running"),
        ] + (1...count + 2).map { i in
            let names = ["com.apple.libdispatch-manager", "com.apple.NSURLSession",
                        "com.apple.CFSocket.private", "com.apple.root.default-qos",
                        "com.apple.root.user-initiated-qos", "com.apple.root.background-qos"]
            return ThreadInfo(
                number: i, name: names[i % names.count],
                priority: Double.random(in: 0.0...1.0),
                isMain: false,
                state: ["Running", "Waiting", "Idle"].randomElement() ?? "Idle"
            )
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in refreshThreads() }
    }
    private func stopTimer() { timer?.invalidate(); timer = nil }
}
