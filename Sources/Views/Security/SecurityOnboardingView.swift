import SwiftUI

struct SecurityOnboardingView: View {
    @ObservedObject var authService: AuthService
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var useBiometrics = true
    @State private var error: String?
    @State private var isAuthenticating = false

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
                Task { await setupVault() }
            } label: {
                Text("Initialize Vault")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(isAuthenticating || password.isEmpty || password != confirmPassword)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    @MainActor
    private func setupVault() async {
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            try authService.setup(password: password, useBiometrics: useBiometrics)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct SecurityLoginView: View {
    @ObservedObject var authService: AuthService
    @State private var password = ""
    @State private var error: String?
    @State private var isAuthenticating = false

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
                Task { await login() }
            } label: {
                Text("Unlock")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(isAuthenticating || password.isEmpty)
            .padding(.horizontal)

            Button {
                isAuthenticating = true
                authService.authenticateWithBiometrics()
            } label: {
                Label("Unlock with Biometrics", systemImage: "faceid")
            }
            .padding(.top)

            Spacer()
        }
        .onAppear {
            isAuthenticating = true
            authService.authenticateWithBiometrics()
        }
        .onChange(of: authService.isAuthenticated) { _, value in
            if value {
                isAuthenticating = false
                error = nil
            }
        }
    }

    @MainActor
    private func login() async {
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            try authService.authenticate(password: password)
            error = nil
        } catch {
            self.error = "Incorrect password"
        }
    }
}
