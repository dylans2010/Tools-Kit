import SwiftUI

/// Real battery drain monitor. The previous version was a visual
/// simulation: a slider-controlled percentage that counted down on a
/// timer and never touched the real battery. This version samples the
/// real UIDevice battery level every 5 seconds, shows the live level
/// and state, and computes a drain rate only from those real samples.
/// The tool keeps its existing id ("battery_drain") so the list entry
/// does not break; its name and description are updated in the
/// view model to match what it now does.
struct Diag_BatteryDrainSimView: View {
    @State private var level: Float = -1
    @State private var stateText = "Unknown"
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var samples: [(Date, Float)] = []
    @State private var startTime: Date?

    private var drainPerHour: Double? {
        guard samples.count >= 2, let first = samples.first, let last = samples.last else { return nil }
        let hours = last.0.timeIntervalSince(first.0) / 3600
        guard hours > 0 else { return nil }
        return Double(first.1 - last.1) * 100 / hours
    }

    var body: some View {
        Form {
            Section("Battery Drain Monitor") {
                VStack(spacing: 16) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 50)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(drainColor)
                                .frame(width: level >= 0 ? geo.size.width * CGFloat(level) : 0, height: 50)
                        }
                        .frame(height: 50)
                    }
                    Text(level >= 0 ? "\(Int(level * 100))%" : "Unknown")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(drainColor)
                    Text("State: \(stateText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let startTime {
                        Text("Monitoring for \(Int(Date().timeIntervalSince(startTime)))s · \(samples.count) samples")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Section("Measured Drain Rate") {
                if let rate = drainPerHour {
                    LabeledContent("Drain Rate") { Text(String(format: "%.2f%%/hr", rate)).monospacedDigit() }
                    if rate > 0, level > 0 {
                        let hours = Double(level) * 100 / rate
                        LabeledContent("Estimated Time Left") { Text(String(format: "%.1f hr", hours)).monospacedDigit() }
                    }
                } else {
                    Text("Keep monitoring running — a rate is computed only after at least two real battery samples, minutes apart. Battery level changes slowly, so this is not instant.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !samples.isEmpty {
                Section("Samples") {
                    ForEach(samples.suffix(15), id: \.0) { sample in
                        HStack {
                            Text(sample.0, style: .time)
                                .font(.caption.monospacedDigit())
                            Spacer()
                            Text("\(Int(sample.1 * 100))%")
                                .font(.caption.monospacedDigit())
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
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring Real Battery")
                    }
                }
            }

            Section {
                Text("This reads the real battery via UIDevice. It does not simulate, reset, or affect your actual battery level.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Battery Drain Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            refresh()
        }
        .onDisappear { stopMonitoring() }
    }

    private var drainColor: Color {
        if level > 0.5 { return .green }
        if level > 0.2 { return .yellow }
        return .red
    }

    private func refresh() {
        level = UIDevice.current.batteryLevel
        switch UIDevice.current.batteryState {
        case .charging: stateText = "Charging"
        case .full: stateText = "Full"
        case .unplugged: stateText = "Unplugged"
        default: stateText = "Unknown"
        }
        if isMonitoring {
            samples.append((Date(), level))
            if samples.count > 200 { samples.removeFirst() }
        }
    }

    private func startMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        isMonitoring = true
        samples = []
        startTime = Date()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in refresh() }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}
