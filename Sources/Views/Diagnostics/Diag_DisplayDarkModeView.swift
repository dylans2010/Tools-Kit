import SwiftUI


struct Diag_DisplayDarkModeView: View {
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
        .navigationTitle("Dark Mode Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Interface Style", UIScreen.main.traitCollection.userInterfaceStyle == .dark ? "Dark" : UIScreen.main.traitCollection.userInterfaceStyle == .light ? "Light" : "Unspecified"),
            ("Darker Colors", UIAccessibility.isDarkerSystemColorsEnabled ? "On" : "Off"),
            ("Reduce Transparency", UIAccessibility.isReduceTransparencyEnabled ? "On" : "Off")
        ]
    }
}
