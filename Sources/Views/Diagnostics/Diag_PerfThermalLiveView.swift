import SwiftUI


struct Diag_PerfThermalLiveView: View {
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
        .navigationTitle("Thermal State Live")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Thermal State", String(describing: ProcessInfo.processInfo.thermalState)),
            ("Low Power Mode", ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off"),
            ("Uptime (min)", "\(Int(ProcessInfo.processInfo.systemUptime / 60))")
        ]
    }
}
