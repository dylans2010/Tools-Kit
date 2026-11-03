import SwiftUI


struct Diag_DisplayColorGamutView: View {
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
        .navigationTitle("Color Gamut")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Gamut", UIScreen.main.traitCollection.displayGamut == .P3 ? "Display P3" : "sRGB"),
            ("Accessibility Contrast", UIScreen.main.traitCollection.accessibilityContrast == .high ? "High" : "Normal"),
            ("Layout Direction", UIScreen.main.traitCollection.layoutDirection == .rightToLeft ? "Right to Left" : "Left to Right"),
            ("Scale", String(format: "%.0fx", UIScreen.main.scale))
        ]
    }
}
