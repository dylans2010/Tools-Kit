import SwiftUI

struct Diag_PowerSourceInfoView: View {
    @State private var powerInfo: [(String, String)] = []
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var history: [(Date, Float, String)] = []

    var body: some View {
        Form {
            Section("Power Source Information") {
                VStack(spacing: 8) {
                    Image(systemName: powerIcon)
                        .font(.system(size: 44))
                        .foregroundStyle(powerColor)
                    Text("Power Source Monitor")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Current Status") {
                ForEach(powerInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption) }
                }
            }

            if !history.isEmpty {
                Section("Power Log") {
                    ForEach(history.suffix(10), id: \.0) { entry in
                        HStack {
                            Text(entry.0, style: .time).font(.caption.monospacedDigit())
                            Spacer()
                            Text("\(Int(entry.1 * 100))%").font(.caption.monospacedDigit())
                            Text(entry.2).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button { isMonitoring ? stopMonitoring() : startMonitoring() } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Power Source")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { UIDevice.current.isBatteryMonitoringEnabled = true; refresh() }
        .onDisappear { stopMonitoring() }
    }

    private var powerIcon: String {
        let state = UIDevice.current.batteryState
        switch state {
        case .charging: return "bolt.fill"
        case .full: return "battery.100.bolt"
        default: return "battery.100"
        }
    }

    private var powerColor: Color {
        let state = UIDevice.current.batteryState
        switch state {
        case .charging: return .green; case .full: return .blue; default: return .secondary
        }
    }

    private func refresh() {
        let device = UIDevice.current
        let pi = ProcessInfo.processInfo
        var info: [(String, String)] = []

        let state = device.batteryState
        let stateStr: String = {
            switch state {
            case .unknown: return "Unknown"; case .unplugged: return "Battery"; case .charging: return "External (Charging)"; case .full: return "External (Full)"
            @unknown default: return "Unknown"
            }
        }()
        info.append(("Power Source", stateStr))

        let level = device.batteryLevel
        info.append(("Battery Level", level >= 0 ? "\(Int(level * 100))%" : "Unknown"))

        info.append(("Low Power Mode", pi.isLowPowerModeEnabled ? "Enabled" : "Disabled"))
        info.append(("Thermal State", thermalStr(pi.thermalState)))
        info.append(("CPU Active", "\(pi.activeProcessorCount)/\(pi.processorCount)"))
        info.append(("Uptime", formatUptime(pi.systemUptime)))

        powerInfo = info
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            refresh()
            let level = UIDevice.current.batteryLevel
            let state: String = {
                switch UIDevice.current.batteryState {
                case .charging: return "Charging"; case .full: return "Full"; case .unplugged: return "Battery"
                default: return "Unknown"
                }
            }()
            history.append((Date(), level, state))
            if history.count > 100 { history.removeFirst() }
        }
    }

    private func stopMonitoring() { timer?.invalidate(); timer = nil; isMonitoring = false }

    private func thermalStr(_ state: ProcessInfo.ThermalState) -> String {
        switch state { case .nominal: return "Nominal"; case .fair: return "Fair"; case .serious: return "Serious"; case .critical: return "Critical"; @unknown default: return "Unknown" }
    }

    private func formatUptime(_ s: TimeInterval) -> String {
        let t = Int(s); let d = t/86400; let h = (t%86400)/3600; let m = (t%3600)/60
        return d > 0 ? "\(d)d \(h)h \(m)m" : "\(h)h \(m)m"
    }
}
