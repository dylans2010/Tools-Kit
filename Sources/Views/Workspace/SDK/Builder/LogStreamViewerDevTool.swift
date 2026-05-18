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
        let headerDescription = "Monitor live log output streams for debugging real-time application behavior."
        return VStack(spacing: 0) {
            DevToolHeader(
                title: "Log Stream Viewer",
                description: headerDescription,
                icon: "list.bullet.rectangle"
            )
            .padding()

            logScrollView
            .background(Color.black.opacity(0.05))
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var logScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(viewModel.logs) { log in
                        logRow(log)
                            .id(log.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.logs.count) { _ in
                scrollToLastLog(with: proxy)
            }
        }
    }

    private func logRow(_ log: HistoryItem) -> some View {
        HStack(alignment: .top) {
            Text("[\(log.timestamp, style: .time)]")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(log.detail)
                .font(.system(.caption, design: .monospaced))
        }
    }

    private func scrollToLastLog(with proxy: ScrollViewProxy) {
        if let lastLogID = viewModel.logs.last?.id {
            proxy.scrollTo(lastLogID)
        }
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
