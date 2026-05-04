import SwiftUI

struct SecurityBiometricControlView: View {
    @State private var faceIDEnabled = true
    @State private var touchIDEnabled = false
    @State private var fallbackToPassword = true
    @State private var retryLimit = 3

    var body: some View {
        Form {
            Section(header: Text("Biometric Authentication")) {
                Toggle("Enable Face ID", isOn: $faceIDEnabled)
                Toggle("Enable Touch ID", isOn: $touchIDEnabled)
            }

            Section(header: Text("Fallback & Limits"), footer: Text("Controls how the system behaves when biometric authentication fails multiple times.")) {
                Toggle("Fallback to Master Password", isOn: $fallbackToPassword)
                Stepper("Retry Limit: \(retryLimit)", value: $retryLimit, in: 1...5)
            }

            Section {
                Button("Reset Biometric Enrollment") {
                    // Reset logic
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Biometric Control")
    }
}
