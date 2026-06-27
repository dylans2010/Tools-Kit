import SwiftUI
public struct MTSettingsView: View {
    @State private var settings = MTSettingsService.shared
    public var body: some View { Form { TextField("Host", text: $settings.gatewayHost) } }
}
