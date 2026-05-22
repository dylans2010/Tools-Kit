import SwiftUI
import LocalAuthentication

struct Diag_PasscodeStatusView: View {
    @State private var isPasscodeSet = false
    @State private var hasChecked = false

    var body: some View {
        Form {
            Section("Device Passcode") {
                VStack(spacing: 12) {
                    Image(systemName: isPasscodeSet ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(isPasscodeSet ? .green : .red)

                    Text(isPasscodeSet ? "Passcode Is Set" : "No Passcode Set")
                        .font(.title2.bold())
                        .foregroundStyle(isPasscodeSet ? .green : .red)

                    Text(isPasscodeSet ? "Your device is protected with a passcode." : "Your device is not protected. Consider setting a passcode in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Security Recommendation") {
                HStack(spacing: 12) {
                    Image(systemName: isPasscodeSet ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundStyle(isPasscodeSet ? .green : .red)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(isPasscodeSet ? "Device Secured" : "Action Required")
                            .font(.subheadline.weight(.medium))
                        Text(isPasscodeSet ? "Passcode protection is active" : "Set a passcode in Settings > Face ID & Passcode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button("Recheck") { checkPasscode() }
            }
        }
        .navigationTitle("Passcode Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkPasscode() }
    }

    private func checkPasscode() {
        let context = LAContext()
        var error: NSError?
        isPasscodeSet = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        hasChecked = true
    }
}
