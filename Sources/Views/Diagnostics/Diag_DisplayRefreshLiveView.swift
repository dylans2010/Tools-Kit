import SwiftUI


struct Diag_DisplayRefreshLiveView: View {
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
        .navigationTitle("Refresh Rate Live")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Maximum FPS", "\(UIScreen.main.maximumFramesPerSecond)"),
            ("ProMotion (120 Hz)", UIScreen.main.maximumFramesPerSecond >= 120 ? "Yes" : "No"),
            ("Native Bounds", "\(Int(UIScreen.main.nativeBounds.width)) x \(Int(UIScreen.main.nativeBounds.height))")
        ]
    }
}
