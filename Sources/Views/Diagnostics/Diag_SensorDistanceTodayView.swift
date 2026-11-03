import SwiftUI
import CoreMotion

struct Diag_SensorDistanceTodayView: View {
    @State private var distance = 0.0
    @State private var steps = 0
    private let pedometer = CMPedometer()

    var body: some View {
        Form {
            Section("Today") {
                LabeledContent("Distance Today (m)") { Text(String(format: "%.1f", distance)).monospacedDigit() }
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
        .navigationTitle("Distance Today")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { data, _ in
            DispatchQueue.main.async {
                guard let data = data else { return }
                steps = data.numberOfSteps.intValue; distance = data.distance?.doubleValue ?? 0
            }
        }
    }
}
