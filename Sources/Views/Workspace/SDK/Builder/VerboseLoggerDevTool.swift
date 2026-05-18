import SwiftUI

struct VerboseLoggerDevTool: DevTool {
    let id = "verbose-logger"
    let name = "Verbose Logger"
    let category = DevToolCategory.diagnostics
    let icon = "text.badge.plus"
    let description = "Stream verbose system logs"

    func render() -> some View {
        VerboseLoggerView()
    }
}

struct VerboseLoggerView: View {
    @StateObject private var viewModel = VerboseLoggerViewModel()

    var body: some View {
        VStack {
            List(viewModel.logs) { log in
                VStack(alignment: .leading) {
                    HStack {
                        Text(log.timestamp, style: .time)
                            .font(.monospaced(.caption2)())
                        Text(log.level)
                            .font(.caption2.bold())
                            .padding(.horizontal, 4)
                            .background(viewModel.color(for: log.level))
                            .cornerRadius(4)
                    }
                    Text(log.message)
                        .font(.monospaced(.caption)())
                }
            }

            HStack {
                Button("Clear") { viewModel.clear() }
                Spacer()
                Button(viewModel.isLogging ? "Stop" : "Start") {
                    viewModel.isLogging.toggle()
                }
            }
            .padding()
        }
    }
}

class VerboseLoggerViewModel: ObservableObject {
    @Published var logs: [VerboseLog] = []
    @Published var isLogging = true
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isLogging else { return }
            let messages = ["Accessing SDK Registry", "Validating connector state", "Memory cleanup initiated", "Thread 4 idling"]
            let log = VerboseLog(level: "DEBUG", message: messages.randomElement()!)
            DispatchQueue.main.async {
                self.logs.append(log)
                if self.logs.count > 50 { self.logs.removeFirst() }
            }
        }
    }

    func clear() { logs = [] }

    func color(for level: String) -> Color {
        switch level {
        case "ERROR": return .red
        case "WARN": return .orange
        case "DEBUG": return .blue
        default: return .green
        }
    }
}
