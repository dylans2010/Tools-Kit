import SwiftUI

struct AddMailAccountView: View {
    @Environment(\.dismiss) private var dismiss

    let onAccountSelected: (MailAccount) -> Void

    @State private var selectedProvider: MailAccount.MailProviderType = .iCloud
    @State private var email = ""
    @State private var appPassword = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var accounts: [MailAccount] = []

    var body: some View {
        NavigationStack {
            List {
                Section("Add account") {
                    providerRow(provider: .iCloud, subtitle: "Use app-specific password")
                    providerRow(provider: .gmail, subtitle: "Use app password from Google")

                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    SecureField("App password", text: $appPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        addAccount()
                    } label: {
                        HStack {
                            if isWorking {
                                ProgressView().tint(.white)
                            }
                            Text(isWorking ? "Adding..." : "Add \(selectedProvider.displayName)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isWorking || email.isEmpty || appPassword.isEmpty)
                }

                Section("Saved accounts") {
                    if accounts.isEmpty {
                        Text("No mail accounts yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(accounts) { account in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(account.email)
                                        .font(.subheadline.weight(.semibold))
                                    Text(account.provider.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Use") {
                                    onAccountSelected(account)
                                    dismiss()
                                }
                                .buttonStyle(.bordered)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    removeAccount(account)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Mail Account")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            accounts = MailStorageService.shared.loadAccounts()
        }
    }

    @ViewBuilder
    private func providerRow(provider: MailAccount.MailProviderType, subtitle: String) -> some View {
        Button {
            selectedProvider = provider
            errorMessage = nil
        } label: {
            HStack {
                Image(systemName: provider == .iCloud ? "icloud.fill" : "envelope.fill")
                    .foregroundStyle(provider == .iCloud ? .blue : .red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selectedProvider == provider {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func addAccount() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard selectedProvider.isValidAddress(normalizedEmail) else {
            errorMessage = "Use a valid \(selectedProvider.displayName) email address."
            return
        }

        isWorking = true
        errorMessage = nil

        Task {
            do {
                let imap = MailIMAPService()
                try await imap.connect(provider: selectedProvider)
                defer { imap.disconnect() }
                try await imap.login(user: normalizedEmail, pass: appPassword)

                guard MailKeychainManager.shared.saveCredentials(email: normalizedEmail, password: appPassword) else {
                    throw NSError(domain: "Mail", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to save credentials to Keychain"])
                }

                var updatedAccounts = MailStorageService.shared.loadAccounts()
                updatedAccounts.removeAll { $0.email.caseInsensitiveCompare(normalizedEmail) == .orderedSame }

                let newAccount = MailAccount(
                    id: UUID(),
                    email: normalizedEmail,
                    provider: selectedProvider,
                    isEnabled: true
                )

                updatedAccounts.append(newAccount)
                MailStorageService.shared.saveAccounts(updatedAccounts)

                await MainActor.run {
                    accounts = updatedAccounts
                    isWorking = false
                    onAccountSelected(newAccount)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func removeAccount(_ account: MailAccount) {
        MailKeychainManager.shared.deleteCredentials(for: account.email)
        accounts.removeAll { $0.id == account.id }
        MailStorageService.shared.saveAccounts(accounts)
    }
}

#Preview {
    AddMailAccountView(onAccountSelected: { _ in })
}
