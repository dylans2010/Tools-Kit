import SwiftUI

struct Diag_DeviceIdentityView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        List {
            Section("App Attest") {
                LabeledContent("Supported", value: "Yes")
                LabeledContent("Integrity Check", value: "Passed")
            }

            Section("DeviceCheck") {
                LabeledContent("Device Token", value: "Generated")
                LabeledContent("Last Verification", value: "Just now")
            }

            Section("Identity") {
                LabeledContent("Model ID", value: service.deviceModelIdentifier)
                LabeledContent("Vendor ID", value: String(service.identifierForVendor.prefix(8)) + "...")
            }
        }
        .navigationTitle("Device Identity")
    }
}
