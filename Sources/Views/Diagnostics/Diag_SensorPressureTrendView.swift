import SwiftUI
import CoreMotion

struct Diag_SensorPressureTrendView: View {
    @State private var pressure = 0.0
    @State private var minPressure = 0.0
    @State private var maxPressure = 0.0
    @State private var samples: [Double] = []
    @State private var isRunning = false
    private let altimeter = CMAltimeter()

    var body: some View {
        Form {
            Section("Pressure") {
                LabeledContent("Current (kPa)") { Text(String(format: "%.2f", pressure)).monospacedDigit() }
                LabeledContent("Min (kPa)") { Text(String(format: "%.2f", minPressure)).monospacedDigit() }
                LabeledContent("Max (kPa)") { Text(String(format: "%.2f", maxPressure)).monospacedDigit() }
                LabeledContent("Average (kPa)") { Text(String(format: "%.2f", samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count))).monospacedDigit() }
                LabeledContent("Samples") { Text("\(samples.count)").monospacedDigit() }
            }
            Section {
                Button { if isRunning { stop() } else { start() } } label: {
                    HStack { Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill"); Text(isRunning ? "Stop" : "Start") }
                }
                .disabled(!CMAltimeter.isRelativeAltitudeAvailable())
            }
        }
        .navigationTitle("Pressure Trend")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stop() }
    }

    private func start() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        isRunning = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { data, _ in
            guard let data = data else { return }
            let p = data.pressure.doubleValue
            pressure = p
            samples.append(p)
            if samples.count == 1 { minPressure = p; maxPressure = p }
            minPressure = min(minPressure, p)
            maxPressure = max(maxPressure, p)
        }
    }

    private func stop() {
        altimeter.stopRelativeAltitudeUpdates()
        isRunning = false
    }
}
