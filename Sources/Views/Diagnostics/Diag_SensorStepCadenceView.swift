import SwiftUI
import CoreMotion

struct Diag_SensorStepCadenceView: View {
    @State private var cadence = 0.0
    @State private var steps = 0
    private let pedometer = CMPedometer()

    var body: some View {
        Form {
            Section("Today") {
                LabeledContent("Current Cadence (steps/s)") { Text(String(format: "%.2f", cadence)).monospacedDigit() }
                LabeledContent("Steps Today") { Text("\(steps)").monospacedDigit() }
            }
            Section {
                Button("Refresh") { load() }
            }
            Section {
                Text("Requires Motion & Fitness permission (NSMotionUsageDescription in Info.plist). If values stay at zero, grant it in Settings > Privacy & Security > Motion & Fitness.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Step Cadence")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { data, _ in
            DispatchQueue.main.async {
                guard let data = data else { return }
                steps = data.numberOfSteps.intValue; cadence = data.currentCadence?.doubleValue ?? 0
            }
        }
    }
}
