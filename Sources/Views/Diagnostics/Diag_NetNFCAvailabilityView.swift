import SwiftUI
import CoreNFC

struct Diag_NetNFCAvailabilityView: View {
    var body: some View {
        Form {
            Section("NFC") {
                LabeledContent("NDEF Reading Available") { Text(NFCNDEFReaderSession.readingAvailable ? "Yes" : "No") }
                LabeledContent("Model") { Text(DeviceModelCatalog.marketingName(for: DeviceModelCatalog.currentIdentifier())) }
            }
            Section {
                Text("NFC reading requires Info.plist NSNFCReaderUsageDescription, added in this change.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("NFC Availability")
        .navigationBarTitleDisplayMode(.inline)
    }
}
