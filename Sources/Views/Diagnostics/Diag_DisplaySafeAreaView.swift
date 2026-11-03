import SwiftUI


struct Diag_DisplaySafeAreaView: View {
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
        .navigationTitle("Display Safe Area")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Bounds", "\(Int(UIScreen.main.bounds.width)) x \(Int(UIScreen.main.bounds.height))"),
            ("Orientation", UIDevice.current.orientation.isPortrait ? "Portrait" : UIDevice.current.orientation.isLandscape ? "Landscape" : "Unknown"),
            ("Idiom", UIDevice.current.userInterfaceIdiom == .phone ? "Phone" : UIDevice.current.userInterfaceIdiom == .pad ? "Pad" : "Other"),
            ("Brightness", "\(Int(UIScreen.main.brightness * 100))%")
        ]
    }
}
