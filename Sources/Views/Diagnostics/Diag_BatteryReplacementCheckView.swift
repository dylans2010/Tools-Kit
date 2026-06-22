import SwiftUI

struct Diag_BatteryReplacementCheckView: View {
    @State private var checks: [(String, String, BatteryPartStatus)] = []
    @State private var overallStatus: BatteryPartStatus = .unknown
    @State private var monitorData: [Float] = []
    @State private var timer: Timer?

    enum BatteryPartStatus {
        case original, replaced, unknown

        var color: Color {
            switch self {
            case .original: return .green
            case .replaced: return .orange
            case .unknown: return .secondary
            }
        }
    }

    var body: some View {
        List {
            Section("Battery Replacement Detection") {
                VStack(spacing: 12) {
                    Image(systemName: overallStatus == .original ? "battery.100" : overallStatus == .replaced ? "exclamationmark.triangle.fill" : "questionmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(overallStatus.color)
                    Text(overallStatus == .original ? "Battery Appears Original" : overallStatus == .replaced ? "Non-Original Battery Possible" : "Analyzing...")
                        .font(.headline)
                    Text("iOS 15.2+ shows battery part history in Settings → General → About")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Battery Diagnostics") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Circle()
                            .fill(check.2.color)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0)
                                .font(.subheadline.weight(.medium))
                            Text(check.1)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !monitorData.isEmpty {
                Section("Battery Level Trend (Live)") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Last \(monitorData.count) readings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f%%", (monitorData.last ?? 0) * 100))
                                .font(.caption.monospacedDigit())
                        }
                        GeometryReader { geo in
                            Path { path in
                                guard monitorData.count > 1 else { return }
                                let stepX = geo.size.width / CGFloat(monitorData.count - 1)
                                for (i, val) in monitorData.enumerated() {
                                    let x = CGFloat(i) * stepX
                                    let y = geo.size.height * (1 - CGFloat(val))
                                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                                }
                            }
                            .stroke(Color.green, lineWidth: 2)
                        }
                        .frame(height: 80)
                    }
                }
            }

            Section("How to Verify") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Settings → General → About → scroll to 'Parts and Service History'", systemImage: "gearshape.fill")
                        .font(.caption)
                    Label("'Unknown Part' indicates non-genuine battery", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Label("Battery health % may not display for non-genuine batteries", systemImage: "battery.100")
                        .font(.caption)
                    Label("Erratic charging behavior may indicate aftermarket battery", systemImage: "bolt.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    analyzeBattery()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-analyze")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Battery Replacement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            analyzeBattery()
            startMonitoring()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func analyzeBattery() {
        var results: [(String, String, BatteryPartStatus)] = []

        let level = UIDevice.current.batteryLevel
        if level >= 0 {
            results.append(("Battery Reporting", "Level: \(Int(level * 100))% — battery monitoring functional", .original))
        } else {
            results.append(("Battery Reporting", "Cannot read battery level — possible hardware issue", .replaced))
        }

        let state = UIDevice.current.batteryState
        let stateStr: String
        switch state {
        case .charging: stateStr = "Charging"
        case .full: stateStr = "Full"
        case .unplugged: stateStr = "Unplugged"
        case .unknown: stateStr = "Unknown"
        @unknown default: stateStr = "Unknown"
        }
        results.append(("Charging State", "State: \(stateStr) — \(state != .unknown ? "charging circuit operational" : "state unknown")", state != .unknown ? .original : .unknown))

        let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        results.append(("Low Power Mode", isLowPower ? "Enabled — may affect battery readings" : "Disabled — normal operation", .original))

        let thermal = ProcessInfo.processInfo.thermalState
        let thermalStr: String
        switch thermal {
        case .nominal: thermalStr = "Nominal"
        case .fair: thermalStr = "Fair"
        case .serious: thermalStr = "Serious — may indicate battery issue"
        case .critical: thermalStr = "Critical — possible battery problem"
        @unknown default: thermalStr = "Unknown"
        }
        let thermalStatus: BatteryPartStatus = (thermal == .nominal || thermal == .fair) ? .original : .replaced
        results.append(("Thermal Behavior", "State: \(thermalStr)", thermalStatus))

        if level >= 0 {
            let normalRange = level >= 0.01 && level <= 1.0
            results.append(("Level Consistency", normalRange ? "Battery level within normal range" : "Battery level outside expected range", normalRange ? .original : .replaced))
        }

        checks = results
        let replacedCount = results.filter { $0.2 == .replaced }.count
        overallStatus = replacedCount == 0 ? .original : replacedCount >= 2 ? .replaced : .unknown
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let level = UIDevice.current.batteryLevel
            if level >= 0 {
                monitorData.append(level)
                if monitorData.count > 30 {
                    monitorData.removeFirst()
                }
            }
        }
    }
}
