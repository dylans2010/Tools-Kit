import SwiftUI
import CoreMotion

struct Diag_SensorFlightsTodayView: View {
    @State private var up = 0
    @State private var down = 0
    private let pedometer = CMPedometer()

    var body: some View {
        Form {
            Section("Today") {
                LabeledContent("Floors Ascended") { Text("\(up)").monospacedDigit() }
                LabeledContent("Floors Descended") { Text("\(down)").monospacedDigit() }
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
        .navigationTitle("Flights Today")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { data, _ in
            DispatchQueue.main.async {
                guard let data = data else { return }
                up = data.floorsAscended?.intValue ?? 0; down = data.floorsDescended?.intValue ?? 0
            }
        }
    }
}
