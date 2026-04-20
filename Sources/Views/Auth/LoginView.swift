import SwiftUI
import Appwrite

struct LoginView: View {
    let onAuthenticated: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreateAccount = false
    @State private var animateHero = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.14),
                    Color(red: 0.09, green: 0.13, blue: 0.22),
                    Color(red: 0.12, green: 0.10, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Welcome back")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Sign in to continue to Tools Kit")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: animateHero ? 0 : -8)
                    .opacity(animateHero ? 1 : 0.7)

                    VStack(spacing: 14) {
                        inputField(title: "Email", placeholder: "you@example.com", text: $email, secure: false, keyboard: .emailAddress)
                        inputField(title: "Password", placeholder: "Enter password", text: $password, secure: true, keyboard: .default)

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 1.0, green: 0.57, blue: 0.57))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Button {
                            signInWithEmail()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                }
                                Text(isLoading ? "Signing in..." : "Sign In")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.12, green: 0.47, blue: 0.95),
                                        Color(red: 0.15, green: 0.67, blue: 0.94)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .foregroundStyle(.white)
                        }
                        .disabled(isLoading)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )

                    VStack(spacing: 12) {
                        Text("or continue with")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))

                        HStack(spacing: 10) {
                            SocialLoginButton(label: "Google", iconText: "G") { signInWithOAuth(provider: "google") }
                            SocialLoginButton(label: "GitHub", iconText: "{}") { signInWithOAuth(provider: "github") }
                            SocialLoginButton(label: "Discord", iconText: "D") { signInWithOAuth(provider: "discord") }
                        }

                        Button("Create account") {
                            showingCreateAccount = true
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
        .sheet(isPresented: $showingCreateAccount) {
            CreateAccountView {
                onAuthenticated()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                animateHero = true
            }
        }
    }

    @ViewBuilder
    private func inputField(title: String, placeholder: String, text: Binding<String>, secure: Bool, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))

            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboard)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
    }

    private func signInWithEmail() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Enter both email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await AuthService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    onAuthenticated()
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
                try await AuthService.shared.signInWithOAuth(provider: provider)
                await MainActor.run {
                    isLoading = false
                    onAuthenticated()
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
    let iconText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 22, height: 22)
                    Text(iconText)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.13), lineWidth: 1)
            )
        }
    }
}

#Preview {
    LoginView(onAuthenticated: {})
}
