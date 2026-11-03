import SwiftUI
import CoreMotion


struct Diag_SecMotionAuthDetailView: View {
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
        .navigationTitle("Motion Auth Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Motion Authorization", String(describing: CMAltimeter.authorizationStatus())),
            ("Activity Available", CMMotionActivityManager.isActivityAvailable() ? "Yes" : "No")
        ]
    }
}
