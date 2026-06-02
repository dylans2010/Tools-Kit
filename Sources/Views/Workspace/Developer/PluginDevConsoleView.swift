import SwiftUI

struct PluginDevConsoleView: View {
    @State private var logs: [ConsoleLog] = [
        ConsoleLog(message: "Plugin system initialized", type: .info),
        ConsoleLog(message: "Loaded CloudSync v1.0.0", type: .info),
        ConsoleLog(message: "Warning: High memory usage detected in PluginID: 4492", type: .warning)
    ]
    @State private var command = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(logs) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Text(log.timestamp, style: .time)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 60, alignment: .leading)

                                Text(log.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(colorForType(log.type))
                            }
                            .id(log.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: logs.count) { _ in
                    if let last = logs.last {
                        proxy.scrollTo(last.id)
                    }
                }
            }
            .background(Color.black.opacity(0.05))

            Divider()

            HStack {
                TextField("Run command (e.g. restart, flush, inspect)", text: $command)
                    .font(.system(size: 12, design: .monospaced))
                    .textFieldStyle(.plain)
                    .onSubmit(executeCommand)

                Button(action: executeCommand) {
                    Image(systemName: "terminal")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Dev Console")
    }

    private func executeCommand() {
        guard !command.isEmpty else { return }
        logs.append(ConsoleLog(message: "> \(command)", type: .info))

        let response: String
        switch command.lowercased() {
        case "restart": response = "Restarting all active plugins..."
        case "flush": response = "Cache flushed successfully."
        case "inspect": response = "Active plugins: 3, Memory: 124MB"
        default: response = "Command not found: \(command)"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            logs.append(ConsoleLog(message: response, type: .info))
        }

        command = ""
    }

    private func colorForType(_ type: ConsoleLog.LogType) -> Color {
        switch type {
        case .info: return .primary
        case .warning: return .orange
        case .error: return .red
        }
    }
}

private struct ConsoleLog: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let message: String
    let type: LogType

    enum LogType {
        case info, warning, error
    }
}
