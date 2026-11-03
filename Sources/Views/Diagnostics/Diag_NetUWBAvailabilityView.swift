import SwiftUI

struct Diag_NetUWBAvailabilityView: View {
    var body: some View {
        Form {
            Section("UWB") {
                let id = DeviceModelCatalog.currentIdentifier()
                let major = Int(id.replacingOccurrences(of: "iPhone", with: "").split(separator: ",").first.map(String.init) ?? "") ?? 0
                LabeledContent("Model") { Text(DeviceModelCatalog.marketingName(for: id)) }
                LabeledContent("UWB Hardware") { Text(major >= 12 ? "Present" : "Not present") }
                LabeledContent("Chip Generation") { Text(major >= 16 ? "U2" : major >= 12 ? "U1" : "None") }
            }
        }
        .navigationTitle("UWB Availability")
        .navigationBarTitleDisplayMode(.inline)
    }
}
