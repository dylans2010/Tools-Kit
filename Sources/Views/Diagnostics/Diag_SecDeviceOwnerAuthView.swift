import SwiftUI
import LocalAuthentication


struct Diag_SecDeviceOwnerAuthView: View {
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
        .navigationTitle("Device Owner Auth")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Can Evaluate", LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) ? "Yes" : "No"),
            ("Biometry Type", String(describing: LAContext().biometryType))
        ]
    }
}
