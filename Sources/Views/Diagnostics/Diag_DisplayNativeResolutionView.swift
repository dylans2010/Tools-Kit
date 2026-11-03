import SwiftUI


struct Diag_DisplayNativeResolutionView: View {
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
        .navigationTitle("Native Resolution")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Screen Bounds", "\(Int(UIScreen.main.bounds.width)) x \(Int(UIScreen.main.bounds.height))"),
            ("Native Bounds", "\(Int(UIScreen.main.nativeBounds.width)) x \(Int(UIScreen.main.nativeBounds.height))"),
            ("Scale", String(format: "%.0fx", UIScreen.main.scale)),
            ("Native Scale", String(format: "%.2fx", UIScreen.main.nativeScale)),
            ("Pixel Count", "\(Int(UIScreen.main.nativeBounds.width * UIScreen.main.nativeBounds.height))")
        ]
    }
}
