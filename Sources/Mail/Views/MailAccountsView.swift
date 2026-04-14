import SwiftUI

struct MailAccountsView: View {
    @State private var accounts: [MailAccount] = []

    var body: some View {
        List {
            ForEach(accounts) { account in
                VStack(alignment: .leading) {
                    Text(account.email)
                        .font(.headline)
                    Text(account.provider.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        delete(account)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
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
