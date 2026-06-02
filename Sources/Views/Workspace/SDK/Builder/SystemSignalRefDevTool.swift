import SwiftUI

struct SystemSignalRefDevTool: DevTool {
    let id = "system-signal-ref"
    let name = "System Signal Reference"
    let category: DevToolCategory = .diagnostics
    let icon = "bolt.horizontal"
    let description = "Reference for POSIX system signals (SIGINT, SIGKILL, etc.)"

    func render() -> some View {
        List {
            signalRow("SIGINT", 2, "Interrupt from keyboard")
            signalRow("SIGKILL", 9, "Kill signal (non-catchable)")
            signalRow("SIGTERM", 15, "Termination signal")
            signalRow("SIGSEGV", 11, "Invalid memory reference")
            signalRow("SIGABRT", 6, "Abort signal")
            signalRow("SIGPIPE", 13, "Broken pipe")
            signalRow("SIGALRM", 14, "Timer signal")
            signalRow("SIGUSR1", 10, "User-defined signal 1")
            signalRow("SIGUSR2", 12, "User-defined signal 2")
        }
    }

    private func signalRow(_ name: String, _ num: Int, _ desc: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(num)").font(.system(.body, design: .monospaced)).foregroundStyle(.tertiary)
        }
    }
}
