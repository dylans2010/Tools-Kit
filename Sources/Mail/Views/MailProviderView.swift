import SwiftUI

struct MailProviderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var selectedProvider: MailAccount.MailProviderType = .iCloud
    @State private var isSaving = false
    @State private var errorMsg: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Gradient header
                VStack(spacing: 16) {
                    ZStack {
                        LinearGradient(
                            colors: [Color.blue, Color.indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)

                    VStack(spacing: 6) {
                        Text("Connect Mail Account")
                            .font(.title2.bold())
                        Text("Your credentials are stored securely in the Keychain.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)

                // Provider selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose Provider")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        ProviderCard(name: "iCloud", icon: "icloud.fill", isEnabled: true, isSelected: selectedProvider == .iCloud) {
                            selectedProvider = .iCloud
                        }
                        ProviderCard(name: "Gmail", icon: "envelope.fill", isEnabled: false, isSelected: false) {}
                        ProviderCard(name: "Outlook", icon: "envelope.badge.fill", isEnabled: false, isSelected: false) {}
                    }
                    .padding(.horizontal)
                }

                // Credentials
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apple ID Email")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        TextField("you@icloud.com", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("App-Specific Password")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        SecureField("xxxx-xxxx-xxxx-xxxx", text: $password)
                            .textContentType(.password)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    Link(destination: URL(string: "https://appleid.apple.com")!) {
                        Label("How to create an app-specific password", systemImage: "questionmark.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                if let error = errorMsg {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }

                // Sign In button
                Button(action: save) {
                    Group {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
                            .opacity(email.isEmpty || password.isEmpty || isSaving ? 0.5 : 1)
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
                .disabled(email.isEmpty || password.isEmpty || isSaving)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Setup Mail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        isSaving = true
        let success = MailKeychainManager.shared.saveCredentials(email: email, password: password)
        if success {
            let account = MailAccount(id: UUID(), email: email, provider: .iCloud, isEnabled: true)
            var current = MailStorageService.shared.loadAccounts()
            if !current.contains(where: { $0.email.lowercased() == email.lowercased() }) {
                current.append(account)
                MailStorageService.shared.saveAccounts(current)
            }
            dismiss()
        } else {
            errorMsg = "Failed to save credentials to Keychain"
            isSaving = false
        }
    }
}

struct ProviderCard: View {
    let name: String
    let icon: String
    let isEnabled: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if isEnabled && isSelected {
                        LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(width: 56, height: 56)
                            .cornerRadius(16)
                    } else {
                        Color(.secondarySystemBackground)
                            .frame(width: 56, height: 56)
                            .cornerRadius(16)
                    }
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isEnabled ? (isSelected ? .white : .blue) : .secondary)
                }
                Text(name)
                    .font(.caption.bold())
                    .foregroundColor(isEnabled ? .primary : .secondary)
                if !isEnabled {
                    Text("Soon")
                        .font(.system(size: 9))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

