import SwiftUI

struct SecurityOnboardingView: View {
    @ObservedObject var authService: AuthService
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var useBiometrics = true
    @State private var error: String?
    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 20)

            Image(systemName: "lock.shield")
                .font(.system(size: 62, weight: .semibold))
                .foregroundStyle(.blue.gradient)
                .padding()
                .background(.ultraThinMaterial, in: Circle())

            Text("Set up your vault")
                .font(.largeTitle.bold())

            Text("Create a master password to protect everything stored in Security Hub.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                SecureField("Master password", text: $password)
                    .textFieldStyle(.roundedBorder)
                SecureField("Confirm password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                Toggle(isOn: $useBiometrics) {
                    Label("Use Face ID / Touch ID", systemImage: "faceid")
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            if let error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Button(action: { Task { await setupVault() } }) {
                Label("Initialize Vault", systemImage: "shield.checkered")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating || password.isEmpty || password != confirmPassword)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
    }

    @MainActor private func setupVault() async {
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
        VStack(spacing: 18) {
            Spacer(minLength: 24)
            Image(systemName: "lock.circle")
                .font(.system(size: 58))
                .foregroundStyle(.blue.gradient)

            Text("Vault Locked")
                .font(.title.bold())

            SecureField("Master password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            Button("Unlock") { Task { await login() } }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating || password.isEmpty)

            Button {
                isAuthenticating = true
                authService.authenticateWithBiometrics { success in
                    isAuthenticating = false
                    if !success { error = "Biometric authentication failed" }
                }
            } label: {
                Label("Unlock with Biometrics", systemImage: "faceid")
            }

            Button("Reset Password", role: .destructive) {
                authService.resetVaultAndPassword()
                password = ""
                error = nil
            }

            Spacer()
        }
        .onAppear {
            authService.authenticateWithBiometrics { success in
                if !success { isAuthenticating = false }
            }
        }
        .onChange(of: authService.isAuthenticated) { _, value in
            if value { isAuthenticating = false; error = nil }
        }
    }

    @MainActor private func login() async {
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
