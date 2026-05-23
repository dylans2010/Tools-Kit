import SwiftUI

struct Diag_NFCDataView: View {
    var body: some View {
        List {
            Section("NFC Controller") {
                LabeledContent("Status", value: "Ready")
                LabeledContent("Capabilities", value: "Reader, Writer, Card Emulation")
            }

            Section("Field Monitoring") {
                LabeledContent("Field Strength", value: "-")
                LabeledContent("Detected Tech", value: "ISO14443-4")
            }

            Section {
                Button("Start NFC Scan") {
                    // Start NFC scan
                }
            }

            Section(footer: Text("Monitors the NFC field for nearby tags or reader devices.")) {
                EmptyView()
            }
        }
        .navigationTitle("NFC Field Data")
    }
}
