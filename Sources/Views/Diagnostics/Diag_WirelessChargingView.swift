import SwiftUI

struct Diag_WirelessChargingView: View {
    @State private var isMonitoring = false
    @State private var batteryState: UIDevice.BatteryState = .unknown
    @State private var batteryLevel: Float = -1
    @State private var chargingHistory: [(Date, Float, String)] = []
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Wireless Charging Test") {
                VStack(spacing: 12) {
                    Image(systemName: chargingIcon)
                        .font(.system(size: 52))
                        .foregroundStyle(chargingColor)
                        .symbolEffect(.pulse, isActive: batteryState == .charging)
                    Text(chargingTitle)
                        .font(.headline)
                    Text(chargingSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Current Status") {
                LabeledContent("Battery Level") {
                    Text(batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "Unknown")
                        .monospacedDigit()
                }
                LabeledContent("Charging State") {
                    Text(stateString)
                        .foregroundStyle(batteryState == .charging ? .green : .secondary)
                }
                LabeledContent("Power Source") {
                    Text(batteryState == .charging ? "External Power (Place on wireless charger to test)" : "Battery")
                }
            }

            Section("Instructions") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Place device on wireless charger", systemImage: "1.circle.fill")
                        .font(.subheadline)
                    Label("Watch for charging state change", systemImage: "2.circle.fill")
                        .font(.subheadline)
                    Label("Monitor that battery level increases", systemImage: "3.circle.fill")
                        .font(.subheadline)
                    Label("Check alignment if not charging", systemImage: "4.circle.fill")
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }

            if !chargingHistory.isEmpty {
                Section("Charging Log") {
                    ForEach(chargingHistory.suffix(10), id: \.0) { entry in
                        HStack {
                            Text(entry.0, style: .time)
                                .font(.caption.monospacedDigit())
                            Spacer()
                            Text("\(Int(entry.1 * 100))%")
                                .font(.caption.monospacedDigit())
                            Text(entry.2)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
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
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
            }

            Section("Compatibility") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 8 and later support Qi wireless charging", systemImage: "iphone.gen2")
                        .font(.caption)
                    Label("iPhone 12+ support MagSafe (up to 15W)", systemImage: "magsafe")
                        .font(.caption)
                    Label("Standard Qi delivers up to 7.5W on iPhone", systemImage: "bolt.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Wireless Charging")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            refreshState()
        }
        .onDisappear { stopMonitoring() }
    }

    private var chargingIcon: String {
        if batteryState == .charging { return "bolt.circle.fill" }
        if batteryState == .full { return "battery.100.bolt" }
        return "battery.100"
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
        case .charging: return "Charging Detected"
        case .full: return "Fully Charged"
        case .unplugged: return "Not Charging"
        default: return "Unknown State"
        }
    }

    private var chargingSubtitle: String {
        switch batteryState {
        case .charging: return "Device is receiving power — wireless charging functional"
        case .full: return "Battery full"
        case .unplugged: return "Place device on wireless charger to test"
        default: return "Enable battery monitoring"
        }
    }

    private var stateString: String {
        switch batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Not Charging"
        default: return "Unknown"
        }
    }

    private func refreshState() {
        batteryState = UIDevice.current.batteryState
        batteryLevel = UIDevice.current.batteryLevel
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            refreshState()
            chargingHistory.append((Date(), batteryLevel, stateString))
            if chargingHistory.count > 100 {
                chargingHistory.removeFirst()
            }
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}
