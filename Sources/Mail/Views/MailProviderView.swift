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
            VStack(alignment: .leading, spacing: 16) {
                Text("Setup Mail")
                    .font(.largeTitle.bold())

                Text("Connect your provider to sync and compose emails.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ProviderCard(name: "iCloud", icon: "icloud.fill", isEnabled: true, isSelected: selectedProvider == .iCloud) {
                            selectedProvider = .iCloud
                        }
                        ProviderCard(name: "Gmail", icon: "envelope.fill", isEnabled: false, isSelected: false) {}
                    }
                    .padding(.vertical, 4)
                }

                VStack(spacing: 12) {
                    TextField("Apple ID Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled(true)
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    SecureField("App-Specific Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    Link("How to create an app-specific password", destination: URL(string: "https://appleid.apple.com")!)
                        .font(.footnote)
                }

                Button(action: save) {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark.shield")
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
                }
                .disabled(email.isEmpty || password.isEmpty || isSaving)

                if let error = errorMsg {
                    Label(error, systemImage: "xmark.octagon.fill")
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(10)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.98, blue: 1.0), Color(red: 0.93, green: 0.95, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Setup Mail")
    }

    private func save() {
        isSaving = true
        let success = MailKeychainManager.shared.saveCredentials(email: email, password: password)
        if success {
            let account = MailAccount(id: UUID(), email: email, provider: .iCloud, isEnabled: true)
            var current = MailStorageService.shared.loadAccounts()
            current.removeAll { $0.email.caseInsensitiveCompare(email) == .orderedSame }
            current.append(account)
            MailStorageService.shared.saveAccounts(current)
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
            VStack {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(isEnabled ? .blue : .secondary)
                Text(name)
                    .font(.caption)
                    .fontWeight(.bold)
                if !isEnabled {
                    Text("Soon")
                        .font(.system(size: 8))
                        .padding(2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .frame(width: 100, height: 100)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}
