import SwiftUI

struct Diag_BatteryDrainRateView: View {
    @State private var startLevel: Float = -1
    @State private var currentLevel: Float = -1
    @State private var samples = 0
    @State private var startTime = Date()
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Drain Rate") {
                LabeledContent("Start Level") { Text(startLevel >= 0 ? "\(Int(startLevel * 100))%" : "—") }
                LabeledContent("Current Level") { Text(currentLevel >= 0 ? "\(Int(currentLevel * 100))%" : "—") }
                LabeledContent("Delta") { Text(startLevel >= 0 && currentLevel >= 0 ? String(format: "%.1f%%", (currentLevel - startLevel) * 100) : "—").monospacedDigit() }
                LabeledContent("Samples (5 s)") { Text("\(samples)").monospacedDigit() }
                LabeledContent("Elapsed (min)") { Text(String(format: "%.1f", Date().timeIntervalSince(startTime) / 60)).monospacedDigit() }
            }
            Section {
                Button("Start Sampling") { start() }
                Button("Stop Sampling") { stop() }
            }
        }
        .navigationTitle("Battery Drain Rate")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { UIDevice.current.isBatteryMonitoringEnabled = true }
        .onDisappear { stop() }
    }

    private func start() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        startLevel = UIDevice.current.batteryLevel
        currentLevel = startLevel
        startTime = Date()
        samples = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            currentLevel = UIDevice.current.batteryLevel
            samples += 1
        }
    }

    private func stop() { timer?.invalidate(); timer = nil }
}
