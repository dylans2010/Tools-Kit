import SwiftUI


struct Diag_BatteryLevelDetailView: View {
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
        .navigationTitle("Battery Level Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Level", "\(Int(UIDevice.current.batteryLevel * 100))%"),
            ("State", String(describing: UIDevice.current.batteryState)),
            ("Monitoring Enabled", UIDevice.current.isBatteryMonitoringEnabled ? "Yes" : "No")
        ]
    }
}
