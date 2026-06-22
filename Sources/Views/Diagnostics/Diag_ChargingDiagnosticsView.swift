import SwiftUI

struct Diag_ChargingDiagnosticsView: View {
    @State private var batteryLevel: Float = -1
    @State private var batteryState: UIDevice.BatteryState = .unknown
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var readings: [(Date, Float, String)] = []
    @State private var chargeRate: String = "Waiting..."

    var body: some View {
        List {
            Section("Charging Port Diagnostics") {
                VStack(spacing: 12) {
                    Image(systemName: chargingIcon)
                        .font(.system(size: 52))
                        .foregroundStyle(chargingColor)
                    Text(chargingTitle)
                        .font(.headline)
                    Text("Connect charger to test port functionality and charging speed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Current Status") {
                LabeledContent("Battery Level") {
                    Text(batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "Unknown").monospacedDigit()
                }
                LabeledContent("Charging State") {
                    Text(stateString).foregroundStyle(batteryState == .charging ? .green : .secondary)
                }
                LabeledContent("Charge Rate") { Text(chargeRate).font(.caption) }
                LabeledContent("Power Source") { Text(powerSourceString) }
            }

            Section("Charging Protocols") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Lightning: Up to 12W (5V/2.4A)", systemImage: "bolt.fill")
                        .font(.caption)
                    Label("USB-C: Up to 27W-30W fast charge", systemImage: "cable.connector")
                        .font(.caption)
                    Label("MagSafe: Up to 15W wireless", systemImage: "magsafe")
                        .font(.caption)
                    Label("Qi: Up to 7.5W wireless", systemImage: "radiowaves.right")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            if readings.count >= 2 {
                Section("Charge Log") {
                    ForEach(readings.suffix(15), id: \.0) { r in
                        HStack {
                            Text(r.0, style: .time).font(.caption.monospacedDigit())
                            Spacer()
                            Text("\(Int(r.1 * 100))%").font(.caption.monospacedDigit())
                            Text(r.2).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    isMonitoring ? stopMonitoring() : startMonitoring()
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop" : "Start Charge Monitoring")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Charging Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            refresh()
        }
        .onDisappear { stopMonitoring() }
    }

    private var chargingIcon: String {
        switch batteryState {
        case .charging: return "bolt.fill"
        case .full: return "battery.100.bolt"
        default: return "powerplug"
        }
    }

    private var chargingColor: Color {
        switch batteryState {
        case .charging: return .green
        case .full: return .blue
        default: return .secondary
        }
    }

    private var chargingTitle: String {
        switch batteryState {
        case .charging: return "Charging Active"
        case .full: return "Fully Charged"
        case .unplugged: return "Not Connected"
        default: return "Unknown"
        }
    }

    private var stateString: String {
        switch batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Unplugged"
        default: return "Unknown"
        }
    }

    private var powerSourceString: String {
        switch batteryState {
        case .charging, .full: return "External Power"
        default: return "Battery"
        }
    }

    private func refresh() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }

    private func startMonitoring() {
        isMonitoring = true
        readings = []
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            refresh()
            readings.append((Date(), batteryLevel, stateString))
            if readings.count > 100 { readings.removeFirst() }
            calculateChargeRate()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func calculateChargeRate() {
        guard readings.count >= 2 else { chargeRate = "Collecting data..."; return }
        let first = readings.first!
        let last = readings.last!
        let timeDiff = last.0.timeIntervalSince(first.0)
        guard timeDiff > 0 else { return }
        let levelDiff = last.1 - first.1
        let ratePerMin = (levelDiff / Float(timeDiff)) * 60 * 100
        if ratePerMin > 0 {
            chargeRate = String(format: "+%.2f%%/min", ratePerMin)
        } else if ratePerMin < 0 {
            chargeRate = String(format: "%.2f%%/min (discharging)", ratePerMin)
        } else {
            chargeRate = "Stable"
        }
    }
}
