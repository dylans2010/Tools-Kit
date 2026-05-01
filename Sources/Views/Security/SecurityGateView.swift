import SwiftUI

struct SecurityGateView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var vaultManager = VaultManager.shared
    @State private var password = ""
    @State private var error: String?
    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Vault Locked")
                .font(.title2.bold())

            VStack(spacing: 15) {
                SecureField("Master Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 40)

                Button(action: authenticate) {
                    if isAuthenticating {
                        ProgressView()
                    } else {
                        Text("Unlock")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
                .disabled(password.isEmpty || isAuthenticating)

                if authService.isBiometricsAvailable {
                    Button {
                        Task { await authService.authenticateWithBiometrics() }
                    } label: {
                        Label("Unlock with Biometrics", systemImage: "faceid")
                    }
                    .padding(.top, 10)
                }
            }

            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Spacer()
        }
        .padding(.top, 50)
    }

    private func authenticate() {
        isAuthenticating = true
        error = nil

        // Dispatch to background thread as key derivation is heavy
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try authService.authenticate(password: password, config: vaultManager.config)
                Task { @MainActor in
                    try? await vaultManager.loadVault()
                    isAuthenticating = false
                }
            } catch {
                Task { @MainActor in
                    self.error = "Incorrect password."
                    isAuthenticating = false
                }
            }
        }
    }
}
