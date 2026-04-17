import SwiftUI

struct MailAccountsView: View {
    @State private var accounts: [MailAccount] = []

    var body: some View {
        List {
            if accounts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No mail accounts")
                        .font(.headline)
                    Text("Add an iCloud account to start syncing your inbox.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            } else {
                ForEach(accounts) { account in
                    HStack(spacing: 12) {
                        Image(systemName: account.provider == .iCloud ? "icloud.fill" : "envelope.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(width: 34, height: 34)
                            .background(Color.blue.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(account.email)
                                .font(.headline)
                            Text(account.provider.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .swipeActions {
                        Button(role: .destructive) {
                            delete(account)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Accounts")
        .onAppear {
            accounts = MailStorageService.shared.loadAccounts()
        }
    }

    private func delete(_ account: MailAccount) {
        MailKeychainManager.shared.deleteCredentials(for: account.email)
        accounts.removeAll { $0.id == account.id }
        MailStorageService.shared.saveAccounts(accounts)
    }
}
