import SwiftUI

struct MailAccountsView: View {
    @StateObject private var mailStore = MailStore.shared
    @State private var showingAddAccount = false

    var body: some View {
        List {
            if mailStore.accounts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No mail accounts")
                        .font(.headline)
                    Text("Add a Gmail, iCloud, Yahoo, or Outlook account to start syncing your inbox.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            } else {
                ForEach(mailStore.accounts) { account in
                    HStack(spacing: 12) {
                        Image(systemName: providerIcon(for: account.provider))
                            .font(.headline)
                            .foregroundColor(providerColor(for: account.provider))
                            .frame(width: 34, height: 34)
                            .background(providerColor(for: account.provider).opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(account.emailAddress)
                                .font(.headline)
                            Text(account.provider.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if account.isActive {
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Button("Switch") {
                                mailStore.setActiveAccount(account.id)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        mailStore.setActiveAccount(account.id)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            mailStore.removeAccount(account)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddAccount = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddMailAccountView { selected in
                mailStore.setActiveAccount(selected.id)
            }
        }
        .onAppear {
            mailStore.reloadAccounts()
        }
    }

    private func providerIcon(for provider: MailAccount.MailProviderType) -> String {
        switch provider {
        case .icloud:
            return "icloud.fill"
        case .gmail:
            return "envelope.fill"
        case .yahoo:
            return "y.circle.fill"
        case .outlook:
            return "o.circle.fill"
        }
    }

    private func providerColor(for provider: MailAccount.MailProviderType) -> Color {
        switch provider {
        case .icloud:
            return .blue
        case .gmail:
            return .red
        case .yahoo:
            return .purple
        case .outlook:
            return .indigo
        }
    }
}
