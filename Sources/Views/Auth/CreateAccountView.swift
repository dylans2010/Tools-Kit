import SwiftUI

struct CreateAccountView: View {
    @Environment(\.dismiss) private var dismiss

    let onAccountCreated: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var errorPulse = false
    private let errorPulseDuration: Double = 0.28

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create account")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Use email and password to create a Tools Kit account.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    inputField(title: "Full name", text: $name, secure: false, keyboard: .default)
                    inputField(title: "Email", text: $email, secure: false, keyboard: .emailAddress)
                    inputField(title: "Password", text: $password, secure: true, keyboard: .default)
                    inputField(title: "Confirm password", text: $confirmPassword, secure: true, keyboard: .default)
                }

                if let errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(errorMessage)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.red.opacity(0.95))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.35), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .scaleEffect(errorPulse ? 1.02 : 1)
                    .animation(.spring(response: errorPulseDuration, dampingFraction: 0.62), value: errorPulse)
                }

                Button(action: createAccount) {
                    HStack {
                        if isWorking {
                            ProgressView().tint(.white)
                        }
                        Text(isWorking ? "Creating..." : "Create Account")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.12, green: 0.47, blue: 0.95), Color(red: 0.15, green: 0.67, blue: 0.94)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(isWorking)

                Spacer()
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.08, blue: 0.13), Color(red: 0.12, green: 0.11, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func inputField(title: String, text: Binding<String>, secure: Bool, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            Group {
                if secure {
                    SecureField(title, text: text)
                } else {
                    TextField(title, text: text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboard)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.09))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(.white)
        }
    }

    private func createAccount() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            animateError()
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            animateError()
            return
        }

        isWorking = true
        errorMessage = nil

        Task {
            do {
                try await AuthService.shared.createAccount(name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: normalizedEmail, password: password)
                await MainActor.run {
                    isWorking = false
                    dismiss()
                    onAccountCreated()
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    errorMessage = error.localizedDescription
                    animateError()
                }
            }
        }
    }

    private func animateError() {
        errorPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + errorPulseDuration) {
            errorPulse = false
        }
    }
}

#Preview {
    CreateAccountView(onAccountCreated: {})
}
