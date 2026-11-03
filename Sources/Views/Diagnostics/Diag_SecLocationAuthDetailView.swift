import SwiftUI
import CoreLocation


struct Diag_SecLocationAuthDetailView: View {
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
        .navigationTitle("Location Auth Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Authorization", String(describing: CLLocationManager().authorizationStatus)),
            ("Location Services Enabled", CLLocationManager.locationServicesEnabled() ? "Yes" : "No"),
            ("Heading Available", CLLocationManager.headingAvailable() ? "Yes" : "No")
        ]
    }
}
