import SwiftUI
public struct PCSettingsView: View {
    @State private var settings = PCSettingsService.shared
    public var body: some View { Form { Section("Gateway") { TextField("URL", text: $settings.gatewayURL) } }.navigationTitle("PC Settings") }
}
