import SwiftUI


struct Diag_DisplayHDRCapabilityView: View {
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
        .navigationTitle("HDR Capability")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Display Gamut", UIScreen.main.traitCollection.displayGamut == .P3 ? "P3" : UIScreen.main.traitCollection.displayGamut == .SRGB ? "sRGB" : "Unknown"),
            ("User Interface Style", UIScreen.main.traitCollection.userInterfaceStyle == .dark ? "Dark" : "Light"),
            ("Brightness", "\(Int(UIScreen.main.brightness * 100))%"),
            ("Max FPS", "\(UIScreen.main.maximumFramesPerSecond)")
        ]
    }
}
