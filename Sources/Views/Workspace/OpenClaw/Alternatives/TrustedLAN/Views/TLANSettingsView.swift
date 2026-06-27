import SwiftUI

public struct TLANSettingsView: View {
    @State private var settings = TLANSettingsService.shared
    @State private var deviceListVM = TLANDeviceListViewModel()
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        Form {
            Section("Connection") {
                Stepper("Timeout: \(Int(settings.connectionTimeout))s", value: $settings.connectionTimeout, in: 5...120)
            }
            Section("Trust") {
                Button("Forget All Devices", role: .destructive) {
                    deviceListVM.forgetAllDevices()
                }
            }
        }
        .navigationTitle("TLAN Settings")
    }
}
