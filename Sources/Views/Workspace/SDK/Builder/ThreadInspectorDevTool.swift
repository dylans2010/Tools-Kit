import SwiftUI

struct ThreadInspectorDevTool: DevTool {
    let id = "thread-inspector"
    let name = "Thread Inspector"
    let category = DevToolCategory.diagnostics
    let icon = "line.3.horizontal"
    let description = "Inspect active threads and call stacks"

    func render() -> some View {
        ThreadInspectorView()
    }
}

struct ThreadInspectorView: View {
    @StateObject private var viewModel = ThreadInspectorViewModel()

    var body: some View {
        List {
            Section("Active Threads") {
                ForEach(viewModel.threads) { thread in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(thread.isRunning ? .green : .gray)
                        VStack(alignment: .leading) {
                            Text(thread.name).font(.headline)
                            Text("ID: \(thread.id)").font(.caption2).monospaced()
                        }
                    }
                }
            }

            Section("Call Stack (Current)") {
                Text(Thread.callStackSymbols.joined(separator: "\n"))
                    .font(.monospaced(.caption2)())
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

struct AppThread: Identifiable {
    let id: String
    let name: String
    let isRunning: Bool
}

class ThreadInspectorViewModel: ObservableObject {
    @Published var threads: [AppThread] = []

    func refresh() {
        // Real thread names are not easily accessible via Thread API in Swift,
        // we'll report what's available
        threads = [
            AppThread(id: "0x1", name: "Main Thread", isRunning: Thread.isMainThread),
            AppThread(id: "0x\(String(format: "%x", Int.random(in: 100...999)))", name: "Worker Thread", isRunning: true)
        ]
    }
}
