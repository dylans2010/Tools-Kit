import SwiftUI

struct SDKConsoleView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var logBus = LogBus.shared
    @StateObject private var runtime = SDKRuntimeEngine.shared

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

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(logBus.logs) { log in
                            HStack(alignment: .top) {
                                Text(log.timestamp, style: .time)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 60, alignment: .leading)

                                Text(log.message)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(log.color)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: logBus.logs.count) { _ in
                    if let last = logBus.logs.last {
                        proxy.scrollTo(last.id)
                    }
                }
            }

            HStack {
                Button("Clear") { logBus.clear() }
                Spacer()
                Button("Export") { /* Export logs */ }
            }
            .padding()
            .background(.thinMaterial)
        }
        .navigationTitle("SDK Console")
        .toolbar {
            Button("Done") { dismiss() }
        }
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
