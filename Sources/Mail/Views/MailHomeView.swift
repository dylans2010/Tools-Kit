import SwiftUI

struct MailHomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var mailStore = MailStore.shared
    @StateObject private var storage = MailStorageService.shared
    @State private var showAddAccount = false

    var body: some View {
        NavigationStack {
            ZStack {
                hexColor("#0D0D14")
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if mailStore.accounts.isEmpty {
                            emptyState
                        } else {
                            ForEach(mailStore.accounts) { account in
                                NavigationLink {
                                    InboxView(account: account, folder: .inbox)
                                } label: {
                                    accountRow(account)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Mail")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddMailAccountView { selected in
                    mailStore.setActiveAccount(selected.id)
                }
            }
            .onAppear {
                mailStore.reloadAccounts()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No mail accounts")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Tap + to connect Gmail, Outlook, Yahoo, Proton, or IMAP.")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(hexColor("#1A1A24"), in: RoundedRectangle(cornerRadius: 16))
    }

    private func accountRow(_ account: MailAccount) -> some View {
        HStack(spacing: 12) {
            Image(systemName: providerIcon(account.providerType))
                .font(.headline)
                .foregroundStyle(providerColor(account.providerType))
                .frame(width: 36, height: 36)
                .background(providerColor(account.providerType).opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(account.emailAddress)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(account.providerType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let unread = unreadCount(for: account)
            if unread > 0 {
                Text("\(unread)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(providerColor(account.providerType), in: Capsule())
            }

            if account.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(14)
        .background(hexColor("#1A1A24"), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .onTapGesture {
            mailStore.setActiveAccount(account.id)
        }
    }

    private func unreadCount(for account: MailAccount) -> Int {
        let key = "\(account.id)_\(MailFolder.inbox.id)"
        return storage.loadThreads(for: key)
            .filter { !$0.isRead }
            .count
    }

    private func providerIcon(_ provider: MailAccount.ProviderType) -> String {
        switch provider {
        case .gmail: return "g.circle.fill"
        case .outlook: return "o.circle.fill"
        case .yahoo: return "y.circle.fill"
        case .proton: return "lock.shield.fill"
        case .imap: return "server.rack"
        case .icloud: return "icloud.fill"
        }
    }

    private func providerColor(_ provider: MailAccount.ProviderType) -> Color {
        switch provider {
        case .gmail: return hexColor("#EA4335")
        case .outlook: return hexColor("#0078D4")
        case .yahoo: return hexColor("#6C3BD1")
        case .proton: return hexColor("#2E8B57")
        case .imap: return hexColor("#7B7B95")
        case .icloud: return .blue
        }
    }

    private func hexColor(_ value: String) -> Color {
        Color(hex: value) ?? .black
    }
}

#Preview {
    MailHomeView()
        .preferredColorScheme(.dark)
}
