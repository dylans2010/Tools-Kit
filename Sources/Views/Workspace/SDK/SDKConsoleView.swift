import SwiftUI

struct SDKConsoleView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var logBus = LogBus.shared
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var filterType: SDKLog.LogType?

    var filteredLogs: [SDKLog] {
        guard let filter = filterType else { return logBus.logs }
        return logBus.logs.filter { $0.type == filter }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Runtime Output").font(.headline)
                Spacer()
                Toggle("Try with SDK", isOn: $runtime.isNoSandboxModeEnabled)
                    .toggleStyle(.button)
                    .tint(.red)
                    .controlSize(.small)
            }
            .padding()
            .background(.thinMaterial)

            HStack(spacing: 8) {
                filterButton("All", type: nil)
                filterButton("Info", type: .info)
                filterButton("Warn", type: .warning)
                filterButton("Error", type: .error)
                filterButton("OK", type: .success)
                Spacer()
                Text("\(filteredLogs.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredLogs) { log in
                            HStack(alignment: .top) {
                                Text(log.timestamp, style: .time)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 60, alignment: .leading)

                                Text(log.type.badge)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(log.color)
                                    .frame(width: 30)

                                Text(log.message)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(log.color)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: logBus.logs.count) { _ in
                    if let last = filteredLogs.last {
                        proxy.scrollTo(last.id)
                    }
                }
            }

            HStack {
                Button("Clear") { logBus.clear() }
                Spacer()
                Button("Export") { exportLogs() }
            }
            .padding()
            .background(.thinMaterial)
        }
        .navigationTitle("SDK Console")
        .toolbar {
            Button("Done") { dismiss() }
        }
        .onAppear {
            forwardSDKLogs()
        }
    }

    private func filterButton(_ label: String, type: SDKLog.LogType?) -> some View {
        Button(label) { filterType = type }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .tint(filterType == type ? .blue : .secondary)
    }

    private func forwardSDKLogs() {
        let recentLogs = SDKLogStore.shared.entries()
        for entry in recentLogs.suffix(50) {
            let logType: SDKLog.LogType
            switch entry.level {
            case .debug, .info: logType = .info
            case .warning: logType = .warning
            case .error: logType = .error
            }
            logBus.log("[\(entry.source)] \(entry.message)", type: logType)
        }
    }

    private func exportLogs() {
        let logText = filteredLogs.map { "[\($0.timestamp)] [\($0.type.badge)] \($0.message)" }.joined(separator: "\n")
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let exportURL = appSupport.appendingPathComponent("sdk_console_export_\(Int(Date().timeIntervalSince1970)).log")
        try? logText.write(to: exportURL, atomically: true, encoding: .utf8)
        logBus.log("Logs exported to \(exportURL.lastPathComponent)", type: .success)
    }

    final class LogBus: ObservableObject {
        static let shared = LogBus()
        @Published var logs: [SDKLog] = []

        func log(_ message: String, type: SDKLog.LogType = .info) {
            DispatchQueue.main.async {
                self.logs.append(SDKLog(message: message, type: type))
            }
        }

        func clear() { logs.removeAll() }
    }
}

struct SDKLog: Identifiable {
    let id = UUID()
    let message: String
    let type: LogType
    let timestamp = Date()

    enum LogType {
        case info, warning, error, success

        var badge: String {
            switch self {
            case .info: return "INF"
            case .warning: return "WRN"
            case .error: return "ERR"
            case .success: return "OK"
            }
        }
    }

    var color: Color {
        switch type {
        case .info: return .primary
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        }
    }
}
