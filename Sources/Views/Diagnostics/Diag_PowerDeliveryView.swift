import SwiftUI

struct Diag_PowerDeliveryView: View {
    @State private var details: [(String, String)] = []
    @State private var batteryLevel: Float = 0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var chargingHistory: [(Date, Float)] = []

    var body: some View {
        Form {
            Section("Power Delivery") {
                VStack(spacing: 12) {
                    Image(systemName: batteryState == .charging ? "bolt.fill" : "powerplug.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(batteryState == .charging ? .green : .secondary)
                    Text(batteryState == .charging ? "Charging Active" : "Not Charging")
                        .font(.headline)
                    Text("Monitor charging speed, power delivery, and charge rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Current Status") {
                LabeledContent("Battery Level") {
                    Text(String(format: "%.0f%%", batteryLevel * 100))
                        .monospacedDigit()
                }
                LabeledContent("Charging State") {
                    Text(stateString(batteryState))
                        .foregroundStyle(batteryState == .charging ? .green : .secondary)
                }
            }

            Section("Device Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Charging Standards") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("USB Power Delivery (PD) fast charging", systemImage: "bolt.fill").font(.caption)
                    Label("Up to 27W wired (iPhone 15 Pro+)", systemImage: "bolt.circle.fill").font(.caption)
                    Label("Up to 20W wired (iPhone 12-14)", systemImage: "bolt.circle").font(.caption)
                    Label("15W MagSafe wireless", systemImage: "magsafe.batterypack.fill").font(.caption)
                    Label("7.5W Qi wireless", systemImage: "bolt.horizontal.circle.fill").font(.caption)
                    Label("15W Qi2 (iPhone 16+)", systemImage: "bolt.horizontal.circle.fill").font(.caption)
                    Label("50% in ~30 min with 20W+ adapter", systemImage: "timer").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Charge History") {
                if chargingHistory.isEmpty {
                    Text("Connect charger and start monitoring")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(chargingHistory.suffix(10).enumerated()), id: \.offset) { _, entry in
                        HStack {
                            Text(String(format: "%.0f%%", entry.1 * 100))
                                .font(.caption.monospaced())
                            Spacer()
                            Text(entry.0, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Power Delivery")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkPower(); startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func stateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Unplugged"
        default: return "Unknown"
        }
    }

    private func checkPower() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState

        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))
        info.append(("Battery Level", String(format: "%.0f%%", batteryLevel * 100)))
        info.append(("Charging", stateString(batteryState)))
        info.append(("Battery Monitoring", "Enabled"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }

    private func startMonitoring() {
        isMonitoring = true
        UIDevice.current.isBatteryMonitoringEnabled = true
        var lastLevel: Float = -1
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            let level = UIDevice.current.batteryLevel
            batteryLevel = level
            batteryState = UIDevice.current.batteryState
            if level != lastLevel {
                chargingHistory.append((Date(), level))
                lastLevel = level
            }
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}
