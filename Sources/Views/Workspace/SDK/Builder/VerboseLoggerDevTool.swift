import SwiftUI

private class _DTLogStore: ObservableObject {
    static let shared = _DTLogStore()
    @Published var entries: [String] = []
    private init() {}
    func log(_ message: String) {
        DispatchQueue.main.async { self.entries.append(message) }
    }
    func clear() {
        self.entries.removeAll()
    }
}

struct VerboseLoggerDevTool: DevTool {
    let id = "verbose-logger"
    let name = "Verbose Logger"
    let category = DevToolCategory.diagnostics
    let icon = "text.badge.plus"
    let description = "Comprehensive application log viewer"

    func render() -> some View {
        VerboseLoggerView()
    }
}

struct VerboseLoggerView: View {
    @StateObject private var viewModel = VerboseLoggerViewModel()
    @State private var filter = ""

    var body: some View {
        VStack {
            HStack {
                TextField("Filter logs...", text: $filter)
                    .textFieldStyle(.roundedBorder)

                Button("Clear") { viewModel.clear() }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            List {
                ForEach(viewModel.logs.filter { filter.isEmpty || $0.message.localizedCaseInsensitiveContains(filter) }) { log in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(log.level)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundStyle(.white)
                                .background(levelColor(log.level), in: RoundedRectangle(cornerRadius: 4))
                            Text(log.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(log.message)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .onAppear { viewModel.start() }
    }

    private func levelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "error": return .red
        case "warning": return .orange
        case "info": return .blue
        default: return .secondary
        }
    }
}

class VerboseLoggerViewModel: ObservableObject {
    @Published var logs: [VerboseLog] = []

    func start() {
        refresh()
    }

    func refresh() {
        let entries = _DTLogStore.shared.entries
        logs = entries.map { entry in
            VerboseLog(level: "INFO", message: entry)
        }
    }

    func clear() {
        _DTLogStore.shared.clear()
        logs.removeAll()
    }
}

#Preview {
    VerboseLoggerView()
}
