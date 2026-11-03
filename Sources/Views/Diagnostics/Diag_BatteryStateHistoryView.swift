import SwiftUI

struct Diag_BatteryStateHistoryView: View {
    @State private var samples: [(String, String)] = []
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Samples") {
                if samples.isEmpty {
                    Text("Tap Start Sampling, then wait for 5-second samples.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(samples.enumerated()), id: \.offset) { _, s in
                        LabeledContent(s.0) { Text(s.1).font(.caption) }
                    }
                }
            }
            Section {
                Button("Start Sampling") { start() }
                Button("Stop Sampling") { stop() }
            }
        }
        .navigationTitle("Battery State History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { UIDevice.current.isBatteryMonitoringEnabled = true }
        .onDisappear { stop() }
    }

    private func start() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let level = UIDevice.current.batteryLevel >= 0 ? "\(Int(UIDevice.current.batteryLevel * 100))%" : "Unknown"
            samples.append((DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium), "\(String(describing: UIDevice.current.batteryState)) \(level)"))
            if samples.count > 50 { samples.removeFirst() }
        }
    }

    private func stop() { timer?.invalidate(); timer = nil }
}
