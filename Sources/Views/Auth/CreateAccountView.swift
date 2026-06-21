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
    @State private var animateHeader = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome To Tools Kit")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Create an account to use Tools Kit, use email and password or choose a provider to create it.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: animateHeader ? 0 : -8)
                    .opacity(animateHeader ? 1 : 0.75)

                    VStack(spacing: 16) {
                        inputField(title: "Name", text: $name, secure: false, keyboard: .default)
                        inputField(title: "Email", text: $email, secure: false, keyboard: .emailAddress)
                        inputField(title: "Password", text: $password, secure: true, keyboard: .default)
                        inputField(title: "Confirm Password", text: $confirmPassword, secure: true, keyboard: .default)

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.red.opacity(0.95))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Button(action: createAccount) {
                            HStack {
                                if isWorking {
                                    ProgressView().tint(.white)
                                }
                                Text(isWorking ? "Creating..." : "Create Account")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white)
                        }
                        .disabled(isWorking)
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .padding(20)
                .padding(.top, 40)
            }
            .background(Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                animateHeader = true
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func inputField(title: String, text: Binding<String>, secure: Bool, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

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
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
    }

    private func createAccount() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isWorking = true
        errorMessage = nil

        Task {
            do {
                try await AccountAuthService.shared.createAccount(name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: normalizedEmail, password: password)
                await MainActor.run {
                    isWorking = false
                    dismiss()
                    onAccountCreated()
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    CreateAccountView(onAccountCreated: {})
}
