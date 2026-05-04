import SwiftUI

struct SecurityOnboardingView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var useBiometrics = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
                .padding(.top, 40)

            VStack(spacing: 8) {
                Text("Secure Your Workspace")
                    .font(.title.bold())
                Text("Create a master password to encrypt your credentials, documents, and files on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                SecureField("Master Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Toggle("Use Face ID / Touch ID", isOn: $useBiometrics)
                    .padding(.horizontal)
            }

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()

            Button {
                setupVault()
            } label: {
                Text("Initialize Vault")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(password.isEmpty || password != confirmPassword)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func setupVault() {
        do {
            try authService.setup(password: password, useBiometrics: useBiometrics)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct SecurityLoginView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var password = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
                .padding(.top, 60)

            Text("Vault Locked")
                .font(.title2.bold())

            SecureField("Enter Master Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button {
                login()
            } label: {
                Text("Unlock")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(password.isEmpty)
            .padding(.horizontal)

            Button {
                authService.authenticateWithBiometrics()
            } label: {
                Label("Unlock with Biometrics", systemImage: "faceid")
            }
            .padding(.top)

            Spacer()
        }
        .onAppear {
            authService.authenticateWithBiometrics()
        }
    }

    private func login() {
        do {
            try authService.authenticate(password: password)
        } catch {
            self.error = "Incorrect password"
        }
    }
}
