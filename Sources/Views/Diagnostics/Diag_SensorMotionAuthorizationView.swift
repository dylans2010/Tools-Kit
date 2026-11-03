import SwiftUI
import CoreMotion


struct Diag_SensorMotionAuthorizationView: View {
    @State private var rows: [(String, String)] = []

    var body: some View {
        Form {
            Section("Results") {
                ForEach(rows, id: \.0) { row in
                    LabeledContent(row.0) { Text(row.1).font(.caption) }
                }
            }

            Section {
                Text("If this shows Not Determined, open any Motion tool (Pedometer, Barometer, Altimeter) once to trigger the system prompt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button { load() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") }
                }
            }
        }
        .navigationTitle("Motion Authorization")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Motion Authorization", String(describing: CMAltimeter.authorizationStatus())),
            ("Activity Available", CMMotionActivityManager.isActivityAvailable() ? "Yes" : "No"),
            ("Step Counting", CMPedometer.isStepCountingAvailable() ? "Available" : "Unavailable"),
            ("Floor Counting", CMPedometer.isFloorCountingAvailable() ? "Available" : "Unavailable"),
            ("Distance", CMPedometer.isDistanceAvailable() ? "Available" : "Unavailable")
        ]
    }
}
