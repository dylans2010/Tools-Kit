import SwiftUI

struct Diag_SensorDriftView: View {
    var body: some View {
        List {
            Section("Calibration Status") {
                DriftRow(sensor: "Accelerometer", drift: "0.002g", status: "Perfect")
                DriftRow(sensor: "Gyroscope", drift: "0.05°/s", status: "Normal")
                DriftRow(sensor: "Magnetometer", drift: "1.2µT", status: "Calibrate")
            }

            Section("Actions") {
                Button("Recalibrate All Sensors") {}
            }
        }
        .navigationTitle("Sensor Drift Analysis")
    }
}

struct DriftRow: View {
    let sensor: String
    let drift: String
    let status: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(sensor)
                    .font(.subheadline)
                Text(drift)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(status)
                .font(.caption.bold())
                .foregroundColor(status == "Calibrate" ? .orange : .green)
        }
    }
}
