import SwiftUI

struct MailProviderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSaving = false
    @State private var errorMsg: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header section
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 10)

                        Image(systemName: "icloud.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 8) {
                        Text("Connect iCloud Mail")
                            .font(.system(size: 28, weight: .bold, design: .rounded))

                        Text("Sign in with your Apple ID and app-specific password.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.top, 40)

                // Input fields
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apple ID")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        TextField("email@icloud.com", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled(true)
                            .padding(16)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("App-Specific Password")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        SecureField("••••••••••••", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(16)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }

                    Link(destination: URL(string: "https://appleid.apple.com")!) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                            Text("How to create an app-specific password")
                        }
                        .font(.footnote.weight(.medium))
                    }
                }
                .padding(.horizontal, 24)

                // Error message
                if let error = errorMsg {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error)
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }

                // Sign in button
                Button(action: save) {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(email.isEmpty || password.isEmpty || isSaving ? Color.gray.opacity(0.3) : Color.blue, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(.white)
                    .shadow(color: email.isEmpty || password.isEmpty || isSaving ? .clear : .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(email.isEmpty || password.isEmpty || isSaving)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("iCloud")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        isSaving = true
        errorMsg = nil

        // Simulate networking delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let success = MailKeychainManager.shared.saveCredentials(email: email, password: password)
            if success {
                let account = MailAccount(id: UUID(), email: email, provider: .iCloud, isEnabled: true)
                var current = MailStorageService.shared.loadAccounts()
                current.removeAll { $0.email.caseInsensitiveCompare(email) == .orderedSame }
                current.append(account)
                MailStorageService.shared.saveAccounts(current)
                dismiss()
            } else {
                errorMsg = "Failed to save credentials securely."
                isSaving = false
            }
        }
    }
}
