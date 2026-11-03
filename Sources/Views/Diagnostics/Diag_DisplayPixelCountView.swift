import SwiftUI


struct Diag_DisplayPixelCountView: View {
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
        .navigationTitle("Display Pixel Count")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Points", "\(Int(UIScreen.main.bounds.width)) x \(Int(UIScreen.main.bounds.height))"),
            ("Native Pixels", "\(Int(UIScreen.main.nativeBounds.width)) x \(Int(UIScreen.main.nativeBounds.height))"),
            ("Scale Factor", "\(UIScreen.main.scale, specifier: "%.0f")x"),
            ("Max Frames Per Second", "\(UIScreen.main.maximumFramesPerSecond)")
        ]
    }
}
