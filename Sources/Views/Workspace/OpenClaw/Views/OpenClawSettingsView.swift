import SwiftUI

struct OpenClawSettingsView: View {
    @AppStorage("openclaw_auto_connect") var autoConnect = true

    var body: some View {
        Form {
            Section("Preferences") {
                Toggle("Auto-connect on Launch", isOn: $autoConnect)
            }

            Section("Reset") {
                Button("Clear All Data", role: .destructive) {
                    // Logic to reset registry and keychain
                }
            }
        }
        .navigationTitle("OpenClaw Settings")
    }
}
