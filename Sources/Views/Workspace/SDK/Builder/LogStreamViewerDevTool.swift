import SwiftUI

struct LogStreamViewerDevTool: DevTool {
    let id = "log-stream-viewer"
    let name = "Log Stream Viewer"
    let category = DevToolCategory.debugging
    let icon = "list.bullet.rectangle"
    let description = "Real-time log stream monitoring"

    func render() -> some View {
        LogStreamViewerView()
    }
}

struct LogStreamViewerView: View {
    @StateObject private var viewModel = LogStreamViewerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Log Stream Viewer",
                description: "Monitor live log output streams for debugging real-time application behavior.",
                icon: "list.bullet.rectangle"
            )
            .padding()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(viewModel.logs) { log in
                            HStack(alignment: .top) {
                                Text("[\(log.timestamp, style: .time)]")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Text(log.message)
                                    .font(.system(.caption, design: .monospaced))
                            }
                            .id(log.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.logs.count) { _ in
                    if let last = viewModel.logs.last {
                        proxy.scrollTo(last.id)
                    }
                }
            }
            .background(Color.black.opacity(0.05))
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

class LogStreamViewerViewModel: ObservableObject {
    @Published var logs: [HistoryItem] = []
    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.logs.append(HistoryItem(title: "Log", detail: "Activity event at \(Date())"))
            if (self?.logs.count ?? 0) > 100 { self?.logs.removeFirst() }
        }
    }

    func stop() {
        timer?.invalidate()
    }
}
