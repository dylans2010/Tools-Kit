import SwiftUI
import CoreMotion

struct Diag_SensorWalkingPaceView: View {
    @State private var pace = 0.0
    @State private var avgPace = 0.0
    private let pedometer = CMPedometer()

    var body: some View {
        Form {
            Section("Today") {
                LabeledContent("Current Pace (s/m)") { Text(String(format: "%.2f", pace)).monospacedDigit() }
                LabeledContent("Average Active Pace (s/m)") { Text(String(format: "%.2f", avgPace)).monospacedDigit() }
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
        .navigationTitle("Walking Pace")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { data, _ in
            DispatchQueue.main.async {
                guard let data = data else { return }
                pace = data.currentPace?.doubleValue ?? 0; avgPace = data.averageActivePace?.doubleValue ?? 0
            }
        }
    }
}
