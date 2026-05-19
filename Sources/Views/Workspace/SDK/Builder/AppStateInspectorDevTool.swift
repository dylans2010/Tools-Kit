import SwiftUI

struct AppStateInspectorDevTool: DevTool {
    let id = "app-state-inspector"
    let name = "App State Inspector"
    let category = DevToolCategory.diagnostics
    let icon = "info.circle"
    let description = "Monitor application lifecycle states"

    func render() -> some View {
        AppStateInspectorView()
    }
}

struct AppStateInspectorView: View {
    @StateObject private var viewModel = AppStateInspectorViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            Section("System Context") {
                HStack(spacing: 16) {
                    StateBadge(label: "Scene", value: "\(scenePhase)", color: .blue)
                    StateBadge(label: "Process", value: "PID \(ProcessInfo.processInfo.processIdentifier)", color: .orange)
                }
                .padding(.vertical, 8)
            }

            Section("Environment Metrics") {
                LabeledContent("Active Duration", value: viewModel.uptime)
                LabeledContent("Thermal State", value: viewModel.thermalState)
                LabeledContent("Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off")
            }

            Section("Lifecycle Audit Log") {
                if viewModel.history.isEmpty {
                    Text("No events recorded").font(.caption2).foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.history) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.subheadline.bold())
                                if !item.detail.isEmpty {
                                    Text(item.detail).font(.system(size: 9)).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(item.timestamp, style: .time).font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section {
                Button(role: .destructive) { viewModel.history.removeAll() } label: {
                    Label("Clear Audit Log", systemImage: "trash")
                }
            }
        }
        .navigationTitle("App State")
        .onChange(of: scenePhase) { old, new in
            viewModel.recordStateChange(to: "\(new)")
        }
    }
}

struct StateBadge: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(color).textCase(.uppercase)
            Text(value).font(.subheadline.bold()).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

class AppStateInspectorViewModel: ObservableObject {
    @Published var uptime = "0:00"
    @Published var thermalState = "Nominal"
    @Published var history: [HistoryItem] = []

    private var startTime = Date()
    private var timer: Timer?

    init() {
        startTracking()
        NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { _ in
            self.updateThermalState()
        }
        updateThermalState()
    }

    func recordStateChange(to state: String) {
        history.insert(HistoryItem(title: "Scene Phase: \(state)", detail: "Triggered by environment change"), at: 0)
    }

    private func startTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let diff = Int(Date().timeIntervalSince(self.startTime))
            let mins = diff / 60
            let secs = diff % 60
            self.uptime = String(format: "%d:%02d", mins, secs)
        }
    }

    private func updateThermalState() {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalState = "Nominal"
        case .fair: thermalState = "Fair"
        case .serious: thermalState = "Serious"
        case .critical: thermalState = "Critical"
        @unknown default: thermalState = "Unknown"
        }
    }
}

#Preview {
    AppStateInspectorView()
}
