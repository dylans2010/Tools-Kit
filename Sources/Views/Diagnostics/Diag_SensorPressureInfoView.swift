import SwiftUI
import CoreMotion


struct Diag_SensorPressureInfoView: View {
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
        .navigationTitle("Pressure Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Relative Altitude Available", CMAltimeter.isRelativeAltitudeAvailable() ? "Yes" : "No"),
            ("Authorization", String(describing: CMAltimeter.authorizationStatus())),
            ("Step Counting", CMPedometer.isStepCountingAvailable() ? "Available" : "Unavailable")
        ]
    }
}
