import SwiftUI
public struct LASettingsView: View {
    @State private var settings = LASettingsService.shared
    public var body: some View { Form { Stepper("Timeout: \(Int(settings.approvalTimeout))s", value: $settings.approvalTimeout) } }
}
