import SwiftUI


struct Diag_PerfFrameRateMaxView: View {
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
        .navigationTitle("Frame Rate Max")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Maximum FPS", "\(UIScreen.main.maximumFramesPerSecond)"),
            ("ProMotion", UIScreen.main.maximumFramesPerSecond >= 120 ? "Yes (120 Hz)" : "No")
        ]
    }
}
