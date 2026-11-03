import SwiftUI


struct Diag_PerfLowPowerDetailView: View {
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
        .navigationTitle("Low Power Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Low Power Mode", ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off"),
            ("Thermal State", String(describing: ProcessInfo.processInfo.thermalState)),
            ("Brightness", "\(Int(UIScreen.main.brightness * 100))%")
        ]
    }
}
