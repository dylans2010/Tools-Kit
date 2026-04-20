import SwiftUI

struct ManageAccountsView: View {
    @Environment(\.dismiss) private var dismiss

    var onAccountSelected: ((MailAccount) -> Void)? = nil

    @StateObject private var mailStore = MailStore.shared

    @State private var loadingProvider: MailAccount.ProviderType?
    @State private var toastMessage: String?
    @State private var showProtonGuide = false

    @State private var imapHost = ""
    @State private var imapPort = "993"
    @State private var smtpHost = ""
    @State private var smtpPort = "465"
    @State private var imapUser = ""
    @State private var imapPassword = ""
    @State private var expandedIMAP = false

    private let providerOrder: [MailAccount.ProviderType] = [.gmail, .outlook, .yahoo, .proton, .imap]

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        accountStats
                        connectedAccountsSection
                        providerSection
                    }
                    .padding(16)
                }

                if let toastMessage {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(Color.red.opacity(0.9), in: Capsule())
                            .padding(.bottom, 18)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Manage Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.headline.weight(.semibold))
                    }
                }
            }
            .sheet(isPresented: $showProtonGuide) {
                protonGuideSheet
            }
            .onAppear {
                mailStore.reloadAccounts()
            }
        }
    }

    private var accountStats: some View {
        HStack(spacing: 10) {
            statCard(title: "Connected", value: "\(mailStore.accounts.count)", symbol: "person.2.fill")
            statCard(title: "Active", value: mailStore.activeAccount?.providerType.displayName ?? "None", symbol: "checkmark.seal.fill")
        }
    }

    private func statCard(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var connectedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Connected Accounts", systemImage: "person.2.fill")
                .font(.headline)

            if mailStore.accounts.isEmpty {
                Text("No accounts connected yet. Add one from the providers below.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(mailStore.accounts) { account in
                        accountRow(account)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Add Provider", systemImage: "plus.circle.fill")
                .font(.headline)

            ForEach(providerOrder, id: \.self) { provider in
                providerButton(for: provider)
            }

            if expandedIMAP {
                imapForm
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .glassCard()
    }

    private func providerButton(for provider: MailAccount.ProviderType) -> some View {
        Button {
            Task { await handleProviderTap(provider) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: providerIcon(provider))
                    .frame(width: 28)
                    .foregroundStyle(providerColor(provider))
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text(buttonSubtitle(provider))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if loadingProvider == provider {
                    ProgressView()
                } else {
                    Image(systemName: provider == .imap ? (expandedIMAP ? "chevron.up" : "chevron.down") : "plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(loadingProvider != nil)
    }

    private func accountRow(_ account: MailAccount) -> some View {
        HStack(spacing: 10) {
            Image(systemName: providerIcon(account.providerType))
                .foregroundStyle(providerColor(account.providerType))
                .frame(width: 28, height: 28)
                .background(providerColor(account.providerType).opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(account.emailAddress)
                    .font(.subheadline.weight(.semibold))
                Text(account.providerType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if account.isActive {
                Text("Active")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2), in: Capsule())
            } else {
                Button("Use") {
                    mailStore.setActiveAccount(account.id)
                    onAccountSelected?(account)
                }
                .buttonStyle(.bordered)
            }

            Button(role: .destructive) {
                mailStore.removeAccount(account)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private var imapForm: some View {
        VStack(spacing: 8) {
            darkField("IMAP Host", text: $imapHost)
            darkField("IMAP Port", text: $imapPort)
            darkField("SMTP Host", text: $smtpHost)
            darkField("SMTP Port", text: $smtpPort)
            darkField("Email / Username", text: $imapUser)
            darkSecureField("Password", text: $imapPassword)

            Button {
                Task { await connectIMAP() }
            } label: {
                HStack {
                    if loadingProvider == .imap {
                        ProgressView().tint(.white)
                    }
                    Text("Connect IMAP Account")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .disabled(loadingProvider != nil || imapHost.isEmpty || imapUser.isEmpty || imapPassword.isEmpty)
        }
        .padding(12)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }

    private var protonGuideSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Proton Bridge Required")
                    .font(.title3.bold())
                Text("Install Proton Bridge, sign in there, then use its generated username/password in the IMAP fields.")
                    .foregroundStyle(.secondary)

                Button("Continue") {
                    showProtonGuide = false
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding(18)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { showProtonGuide = false }
                }
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#090E17") ?? .black, Color(hex: "#151E2C") ?? .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func buttonSubtitle(_ provider: MailAccount.ProviderType) -> String {
        switch provider {
        case .gmail: return "OAuth sign in"
        case .outlook: return "Microsoft OAuth"
        case .yahoo: return "Yahoo OAuth"
        case .proton: return "Bridge-assisted IMAP"
        case .imap: return "Custom server"
        case .icloud: return "Apple mail"
        }
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
        case .gmail: return Color(hex: "#EA4335") ?? .red
        case .outlook: return Color(hex: "#0078D4") ?? .blue
        case .yahoo: return Color(hex: "#6C3BD1") ?? .purple
        case .proton: return Color(hex: "#2E8B57") ?? .green
        case .imap: return Color(hex: "#9AA0B5") ?? .gray
        case .icloud: return .blue
        }
    }

    private func darkField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private func darkSecureField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private func handleProviderTap(_ provider: MailAccount.ProviderType) async {
        if provider == .imap {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedIMAP.toggle()
            }
            return
        }

        if provider == .proton {
            showProtonGuide = true
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedIMAP = true
            }
            return
        }

        loadingProvider = provider
        defer { loadingProvider = nil }

        do {
            let session: MailSession
            switch provider {
            case .gmail:
                session = try await OAuthManager.shared.authenticate(provider: .gmail)
            case .outlook:
                session = try await OAuthManager.shared.authenticate(provider: .outlook)
            case .yahoo:
                session = try await OAuthManager.shared.authenticate(provider: .yahoo)
            case .proton, .imap, .icloud:
                return
            }

            await AccountManager.shared.registerAuthenticatedAccount(session)
            let account = await MainActor.run { AccountManager.shared.activeAccount ?? AccountManager.shared.addAccount(session) }
            onAccountSelected?(account)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func connectIMAP() async {
        loadingProvider = .imap
        defer { loadingProvider = nil }

        let imapPortValue = UInt16(imapPort) ?? 993
        let smtpPortValue = UInt16(smtpPort) ?? 465

        do {
            let credentials = MailCredentials(
                email: imapUser.trimmingCharacters(in: .whitespacesAndNewlines),
                password: imapPassword,
                host: imapHost.trimmingCharacters(in: .whitespacesAndNewlines),
                port: imapPortValue,
                smtpHost: smtpHost.trimmingCharacters(in: .whitespacesAndNewlines),
                smtpPort: smtpPortValue,
                accessToken: nil,
                refreshToken: nil
            )

            let session = try await IMAPProvider().authenticate(credentials: credentials)
            guard MailKeychainManager.shared.saveCredentials(email: session.email, password: imapPassword) else {
                throw NSError(domain: "Mail", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to save credentials to keychain"])
            }

            let account = await MainActor.run { AccountManager.shared.addAccount(session) }
            onAccountSelected?(account)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            toastMessage = message
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
}

private extension View {
    func glassCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

#Preview {
    ManageAccountsView()
}
