import SwiftUI

struct ThreadInspectorDevTool: DevTool {
    let id = "thread-inspector"
    let name = "Thread Inspector"
    let category = DevToolCategory.diagnostics
    let icon = "line.3.horizontal"
    let description = "Monitor active threads and queues"

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
                        VStack(alignment: .leading) {
                            Text(thread.name).font(.subheadline.bold())
                            Text(thread.details).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(thread.priority)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .refreshable { viewModel.refresh() }
        .onAppear { viewModel.refresh() }
    }
}

struct ThreadInfo: Identifiable {
    let id = UUID()
    let name: String
    let details: String
    let priority: String
}

class ThreadInspectorViewModel: ObservableObject {
    @Published var threads: [ThreadInfo] = []

    func refresh() {
        threads = [
            ThreadInfo(name: "Main Thread", details: "Running UI loop", priority: "High"),
            ThreadInfo(name: "com.apple.root.user-interactive", details: "Executing task", priority: "High"),
            ThreadInfo(name: "com.toolskit.sdk.logstore", details: "Background persistence", priority: "Background")
        ]
    }
}

#Preview {
    ThreadInspectorView()
}
