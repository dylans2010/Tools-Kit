import SwiftUI

struct SecurityAutoLockSettingsView: View {
    @State private var autoLockTimeout: Int = 300 // Seconds
    @State private var lockOnBackground: Bool = true
    @State private var requireAuthOnOpen: Bool = true

    let timeoutOptions = [
        (30, "30 Seconds"),
        (60, "1 Minute"),
        (300, "5 Minutes"),
        (600, "10 Minutes"),
        (1800, "30 Minutes"),
        (3600, "1 Hour")
    ]

    var body: some View {
        Form {
            Section(header: Text("Inactivity Timeout")) {
                Picker("Auto-lock after", selection: $autoLockTimeout) {
                    ForEach(timeoutOptions, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }
            }

            Section(header: Text("Background Behavior")) {
                Toggle("Lock on Background", isOn: $lockOnBackground)
                Toggle("Require Auth on App Open", isOn: $requireAuthOnOpen)
            }

            Section(footer: Text("Auto-lock ensures your vault is secured even if you forget to manually lock it.")) {
                Button("Apply Settings") {
                    // Save to UserDefaults
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Auto-Lock Settings")
    }
}
