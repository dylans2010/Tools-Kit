import SwiftUI
public struct QRSettingsView: View {
    @State private var settings = QRSettingsService.shared
    public var body: some View { Form { Toggle("Auto Connect", isOn: $settings.autoConnect) } }
}
