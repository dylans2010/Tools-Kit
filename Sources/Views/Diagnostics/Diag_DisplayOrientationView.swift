import SwiftUI


struct Diag_DisplayOrientationView: View {
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
        .navigationTitle("Display Orientation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Orientation", String(describing: UIDevice.current.orientation)),
            ("Width (pt)", "\(Int(UIScreen.main.bounds.width))"),
            ("Height (pt)", "\(Int(UIScreen.main.bounds.height))"),
            ("Is Portrait", UIDevice.current.orientation.isPortrait ? "Yes" : "No")
        ]
    }
}
