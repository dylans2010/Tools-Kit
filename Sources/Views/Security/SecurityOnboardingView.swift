import SwiftUI

struct SecurityOnboardingView: View {
    @ObservedObject var vaultManager = VaultManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var useBiometrics = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Create Master Password")
                            .font(.headline)
                        Text("This password is used to derive your encryption key. It is never stored in plaintext and cannot be recovered if lost.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)

                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }

                Section {
                    Toggle("Enable Face ID / Touch ID", isOn: $useBiometrics)
                        .disabled(!AuthService.shared.isBiometricsAvailable)

                    if !AuthService.shared.isBiometricsAvailable {
                        Text("Biometrics are not available on this device.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: setupVault) {
                        if vaultManager.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Initialize Vault")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(password.isEmpty || password != confirmPassword || vaultManager.isLoading)
                }
            }
            .navigationTitle("Vault Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func setupVault() {
        guard password == confirmPassword else {
            error = "Passwords do not match."
            return
        }

        do {
            try vaultManager.initializeVault(password: password, useBiometrics: useBiometrics)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
