import SwiftUI
import NearbyInteraction

/// Real UWB availability from NearbyInteraction. The previous version
/// inferred "U1 vs U2" from the model-number prefix — iOS does not expose
/// the UWB chip generation to apps, so that generation label was
/// invented. This version reports NISession.isSupported (the real API)
/// plus the device model for context, and does not claim a chip generation.
struct Diag_NetUWBAvailabilityView: View {
    var body: some View {
        Form {
            Section("UWB") {
                let id = DeviceModelCatalog.currentIdentifier()
                LabeledContent("Model") { Text(DeviceModelCatalog.marketingName(for: id)) }
                LabeledContent("Nearby Interaction Supported") { Text(NISession.isSupported ? "Yes" : "No") }
                LabeledContent("UWB Hardware") { Text(NISession.isSupported ? "Present" : "Not present") }
            }
            Section {
                Text("The U1/U2 chip generation is not exposed by any public iOS API, so this tool does not label it. NISession.isSupported is the live check Apple provides.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("UWB Availability")
        .navigationBarTitleDisplayMode(.inline)
    }
}
