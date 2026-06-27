import SwiftUI
public struct TLANSettingsView: View {
    @State private var settings = TLANSettingsService.shared
    public var body: some View {
        Form { Section("Connection") { TextField("Gateway Host", text: .constant("")); Stepper("Timeout: \(Int(settings.connectionTimeout))s", value: $settings.connectionTimeout, in: 5...120) }
            Section("Trust") { Button("Forget Device", role: .destructive) {} }
        }.navigationTitle("TLAN Settings")
    }
}
