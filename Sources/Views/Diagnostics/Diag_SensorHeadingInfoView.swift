import SwiftUI
import CoreLocation


struct Diag_SensorHeadingInfoView: View {
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
        .navigationTitle("Heading Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Heading Available", CLLocationManager.headingAvailable() ? "Yes" : "No"),
            ("Location Services Enabled", CLLocationManager.locationServicesEnabled() ? "Yes" : "No"),
            ("Authorization", String(describing: CLLocationManager().authorizationStatus))
        ]
    }
}
