import SwiftUI

struct ManageAccountsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mailStore = MailStore.shared
    @State private var loadingProvider: MailAccount.ProviderType?

    var onSelectAccount: ((MailAccount) -> Void)?

    init(onSelectAccount: ((MailAccount) -> Void)? = nil) {
        self.onSelectAccount = onSelectAccount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        connectedAccountsList

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Add Provider")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(MailAccount.ProviderType.allCases, id: \.self) { provider in
                                providerButton(for: provider)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var connectedAccountsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Accounts")
                .font(.headline)
                .padding(.horizontal)

            if mailStore.accounts.isEmpty {
                Text("No accounts connected.")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(mailStore.accounts) { account in
                    HStack {
                        HStack {
                            providerIconView(for: account.providerType)

                            VStack(alignment: .leading) {
                                Text(account.emailAddress).font(.subheadline.bold())
                                Text(account.providerType.displayName).font(.caption).foregroundStyle(.secondary)
                            }

                            Spacer()

                            if account.isActive {
                                Text("Active").font(.caption2.bold()).padding(.horizontal, 8).padding(.vertical, 4).background(Color.green.opacity(0.2), in: Capsule()).foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectAccount?(account)
                            dismiss()
                        }

                        Button(role: .destructive) {
                            mailStore.removeAccount(account)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                    .padding()
                    .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
            }
        }
    }

    private func providerButton(for provider: MailAccount.ProviderType) -> some View {
        Button {
            Task { await handleProviderTap(provider) }
        } label: {
            HStack {
                providerIconView(for: provider)
                Text(provider.displayName).font(.subheadline.bold())
                Spacer()
                Image(systemName: "plus.circle.fill").foregroundStyle(.blue)
            }
            .padding()
            .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private func providerIconView(for provider: MailAccount.ProviderType) -> some View {
        Image(systemName: "envelope.fill")
            .foregroundStyle(providerColor(provider))
            .frame(width: 32, height: 32)
            .background(providerColor(provider).opacity(0.1), in: Circle())
    }

    private func providerColor(_ provider: MailAccount.ProviderType) -> Color {
        switch provider {
        case .gmail: return .red
        case .outlook: return .blue
        case .yahoo: return .purple
        case .proton: return .green
        case .imap, .icloud: return .gray
        }
    }

    private func handleProviderTap(_ provider: MailAccount.ProviderType) async {
        loadingProvider = provider

        do {
            let credentials = MailCredentials.oauth()
            let session: MailSession
            switch provider {
            case .gmail:
                session = try await GmailProvider().authenticate(credentials: credentials)
            case .outlook:
                session = try await OutlookProvider().authenticate(credentials: credentials)
            case .yahoo:
                session = try await YahooMailProvider().authenticate(credentials: credentials)
            case .proton:
                session = try await ProtonMailProvider().authenticate(credentials: credentials)
            case .icloud:
                session = try await IMAPProvider().authenticate(credentials: MailCredentials(
                    email: "",
                    password: nil,
                    host: "imap.mail.me.com",
                    port: 993,
                    smtpHost: "smtp.mail.me.com",
                    smtpPort: 587
                ))
            case .imap:
                session = try await IMAPProvider().authenticate(credentials: credentials)
            }

            let account = MailAccount(
                id: session.id,
                emailAddress: session.email,
                providerType: session.provider,
                displayName: session.displayName,
                accessTokenExpiration: session.accessTokenExpiration,
                imapHost: session.imapHost,
                imapPort: session.imapPort,
                smtpHost: session.smtpHost,
                smtpPort: session.smtpPort,
                isActive: false
            )

            await MainActor.run {
                mailStore.addOrUpdateAccount(account, makeActive: true)
                loadingProvider = nil
            }
        } catch {
            print("Authentication failed: \(error)")
            await MainActor.run {
                loadingProvider = nil
            }
        }
    }
}
