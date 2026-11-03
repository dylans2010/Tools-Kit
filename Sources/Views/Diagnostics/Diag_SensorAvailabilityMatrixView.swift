import SwiftUI
import CoreMotion


struct Diag_SensorAvailabilityMatrixView: View {
    @State private var rows: [(String, String)] = []

    var body: some View {
        Form {
            Section("Results") {
                ForEach(rows, id: \.0) { row in
                    LabeledContent(row.0) { Text(row.1).font(.caption) }
                }
            }

            Section {
                Button { load() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") }
                }
            }
        }
        .navigationTitle("Sensor Availability Matrix")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Accelerometer", CMMotionManager().isAccelerometerAvailable ? "Available" : "Unavailable"),
            ("Gyroscope", CMMotionManager().isGyroAvailable ? "Available" : "Unavailable"),
            ("Magnetometer", CMMotionManager().isMagnetometerAvailable ? "Available" : "Unavailable"),
            ("Device Motion", CMMotionManager().isDeviceMotionAvailable ? "Available" : "Unavailable"),
            ("Altimeter", CMAltimeter.isRelativeAltitudeAvailable() ? "Available" : "Unavailable"),
            ("Step Counting", CMPedometer.isStepCountingAvailable() ? "Available" : "Unavailable"),
            ("Motion Activity", CMMotionActivityManager.isActivityAvailable() ? "Available" : "Unavailable")
        ]
    }
}
