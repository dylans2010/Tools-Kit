import SwiftUI

struct MailProviderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var selectedProvider: MailAccount.MailProviderType = .iCloud
    @State private var isSaving = false
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section(header: Text("Choose Provider")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ProviderCard(name: "iCloud", icon: "icloud.fill", isEnabled: true, isSelected: selectedProvider == .iCloud) {
                            selectedProvider = .iCloud
                        }
                        ProviderCard(name: "Gmail", icon: "envelope.fill", isEnabled: false, isSelected: false) {}
                    }
                    .padding(.vertical, 8)
                }
            }

            Section(header: Text("iCloud Credentials")) {
                TextField("Apple ID Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                SecureField("App-Specific Password", text: $password)

                Link("How to create app-specific password?", destination: URL(string: "https://appleid.apple.com")!)
                    .font(.caption)
            }

            Section {
                Button(action: save) {
                    if isSaving {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty || isSaving)
            }

            if let error = errorMsg {
                Section {
                    Text(error).foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Setup Mail")
    }

    private func save() {
        isSaving = true
        let success = MailKeychainManager.shared.saveCredentials(email: email, password: password)
        if success {
            let account = MailAccount(id: UUID(), email: email, provider: .iCloud, isEnabled: true)
            var current = MailStorageService.shared.loadAccounts()
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
