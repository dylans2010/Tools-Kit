import SwiftUI

struct LoginView: View {
    let onAuthenticated: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreateAccount = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Account")
                                .font(.system(size: 32, weight: .bold))
                            Text("Sign in to your account to enable AI features.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 40)

                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                TextField("Email", text: $email)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                SecureField("Password", text: $password)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button {
                                signIn()
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    }
                                    Text("Sign In")
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primary)
                                .foregroundStyle(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                        }

                        VStack(spacing: 16) {
                            HStack {
                                Rectangle().frame(height: 1).foregroundStyle(Color(.separator))
                                Text("OR").font(.caption2).foregroundStyle(.secondary)
                                Rectangle().frame(height: 1).foregroundStyle(Color(.separator))
                            }

                            HStack(spacing: 12) {
                                SocialLoginButton(label: "Google") { signInWithOAuth(provider: "google") }
                                SocialLoginButton(label: "GitHub") { signInWithOAuth(provider: "github") }
                            }

                            Button("Create Account") {
                                showingCreateAccount = true
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateAccount) {
            CreateAccountView {
                onAuthenticated()
                dismiss()
            }
        }
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await AccountAuthService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    onAuthenticated()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func signInWithOAuth(provider: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await AccountAuthService.shared.signInWithOAuth(provider: provider)
                await MainActor.run {
                    isLoading = false
                    onAuthenticated()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private struct SocialLoginButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
