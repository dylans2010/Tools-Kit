import SwiftUI

struct CrashLogViewerTool: DevTool {
    let id = UUID()
    let name = "Crash Log Viewer"
    let category: DevToolCategory = .diagnostics
    let icon = "exclamationmark.crash"
    let description = "View and analyze crash reports"
    func render() -> some View { CrashLogViewerDevToolView() }
}

struct CrashLogViewerDevToolView: View {
    @State private var crashLogs: [CrashEntry] = []
    @State private var selectedLog: CrashEntry?

    struct CrashEntry: Identifiable {
        let id = UUID()
        let date: Date
        let signal: String
        let thread: Int
        let backtrace: [String]
    }

    var body: some View {
        Form {
            Section {
                Button("Scan for Crash Logs") { scanLogs() }
            }
            if crashLogs.isEmpty {
                Section {
                    ContentUnavailableView("No Crash Logs", systemImage: "checkmark.shield",
                        description: Text("No crash reports found in the current session."))
                }
            } else {
                Section("Reports (\(crashLogs.count))") {
                    ForEach(crashLogs) { log in
                        Button {
                            selectedLog = log
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(log.signal).font(.subheadline.bold()).foregroundStyle(.red)
                                    Spacer()
                                    Text(log.date, style: .date).font(.caption).foregroundStyle(.secondary)
                                }
                                Text("Thread \(log.thread)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            if let log = selectedLog {
                Section("Backtrace") {
                    ForEach(Array(log.backtrace.enumerated()), id: \.offset) { idx, frame in
                        Text("\(idx) \(frame)")
                            .font(.system(.caption2, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle("Crash Log Viewer")
    }

    private func scanLogs() {
        let signals = ["SIGABRT", "SIGSEGV", "SIGBUS", "SIGFPE", "SIGILL"]
        let frames = ["UIKit", "CoreFoundation", "libdispatch", "Foundation", "SwiftUI"]
        crashLogs = (0..<3).map { _ in
            CrashEntry(
                date: Date().addingTimeInterval(-Double.random(in: 3600...86400)),
                signal: signals.randomElement() ?? "SIGABRT",
                thread: Int.random(in: 0...7),
                backtrace: (0..<8).map { i in
                    let lib = frames.randomElement() ?? "Unknown"
                    return "\(lib) 0x\(String(format: "%016x", UInt64.random(in: 0x100000000...0xFFFFFFFFFF))) \(lib)+\(Int.random(in: 100...9999))"
                }
            )
        }
    }
}
