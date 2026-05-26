import SwiftUI

struct PluginEventMonitorView: View {
    @StateObject private var manager = SDKPluginManager.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var isMonitoring = true

    var body: some View {
        VStack(spacing: 0) {
            header

            List {
                let pluginLogs = logStore.entries.filter { $0.source?.contains("Plugin") ?? false }
                if pluginLogs.isEmpty {
                    ContentUnavailableView("No Plugin Events", systemImage: "bolt.horizontal.circle", description: Text("Logs specifically from plugin operations will appear here."))
                } else {
                    ForEach(pluginLogs) { event in
                        HStack(alignment: .top, spacing: 12) {
                            Rectangle()
                                .fill(color(for: event.level))
                                .frame(width: 4)
                                .clipShape(Capsule())

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(event.source ?? "Unknown Plugin").font(.caption.bold())
                                    Spacer()
                                    Text(event.timestamp.formatted(date: .omitted, time: .standard))
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                }
                                Text(event.message)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Event Monitor")
    }

    private var header: some View {
        HStack {
            Label("Live Plugin Activity", systemImage: "waveform.path.ecg")
                .font(.caption.bold())
            Spacer()
            Button("Clear Logs") { logStore.clear() }
                .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
