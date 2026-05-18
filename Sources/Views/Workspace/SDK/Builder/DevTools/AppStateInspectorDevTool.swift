import SwiftUI

struct AppStateInspectorTool: DevTool {
    let id = UUID()
    let name = "App State Inspector"
    let category: DevToolCategory = .diagnostics
    let icon = "app.badge"
    let description = "Inspect current application state"
    func render() -> some View { AppStateInspectorDevToolView() }
}

struct AppStateInspectorDevToolView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var stateHistory: [(String, Date)] = []

    var body: some View {
        Form {
            Section("Current State") {
                LabeledContent("Scene Phase", value: scenePhaseString)
                LabeledContent("Process ID", value: "\(ProcessInfo.processInfo.processIdentifier)")
                LabeledContent("Process Name", value: ProcessInfo.processInfo.processName)
                LabeledContent("System Uptime", value: formatUptime(ProcessInfo.processInfo.systemUptime))
                LabeledContent("Thermal State", value: thermalStateString)
                LabeledContent("Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Yes" : "No")
            }
            Section("Arguments") {
                ForEach(ProcessInfo.processInfo.arguments, id: \.self) { arg in
                    Text(arg).font(.system(.caption, design: .monospaced))
                }
            }
            Section("Environment (sample)") {
                let env = Array(ProcessInfo.processInfo.environment.prefix(10))
                ForEach(env, id: \.key) { key, value in
                    VStack(alignment: .leading) {
                        Text(key).font(.caption.bold())
                        Text(value).font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary)
                    }
                }
            }
            if !stateHistory.isEmpty {
                Section("State Changes") {
                    ForEach(Array(stateHistory.enumerated()), id: \.offset) { _, entry in
                        LabeledContent(entry.0) {
                            Text(entry.1, style: .time).font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("App State Inspector")
        .onChange(of: scenePhase) { _, newPhase in
            stateHistory.insert((String(describing: newPhase), Date()), at: 0)
        }
    }

    private var scenePhaseString: String {
        switch scenePhase {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }

    private var thermalStateString: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func formatUptime(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = Int(interval) % 3600 / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
