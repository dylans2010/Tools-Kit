import SwiftUI

struct ManageAccountsView: View {
    @Environment(\.dismiss) private var dismiss

    var onAccountsChanged: (() -> Void)? = nil

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
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        connectedAccountsCard
                        connectProvidersCard
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
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.9), in: Capsule())
                            .padding(.bottom, 18)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Manage Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.88), value: toastMessage)
            .sheet(isPresented: $showProtonGuide) {
                protonGuideSheet
            }
            .onAppear {
                mailStore.reloadAccounts()
            }
        }
    }

    private var connectedAccountsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Connected Accounts", systemImage: "person.2.fill")
                .font(.headline)

            if mailStore.accounts.isEmpty {
                ContentUnavailableView(
                    "No accounts connected",
                    systemImage: "tray",
                    description: Text("Use the provider buttons below to connect Gmail, Outlook, Yahoo, Proton, or IMAP.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            } else {
                ForEach(mailStore.accounts) { account in
                    accountRow(account)
                    if account.id != mailStore.accounts.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func accountRow(_ account: MailAccount) -> some View {
        HStack(spacing: 12) {
            Image(systemName: providerIcon(account.providerType))
                .font(.headline)
                .foregroundStyle(providerColor(account.providerType))
                .frame(width: 34, height: 34)
                .background(providerColor(account.providerType).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(account.emailAddress)
                    .font(.subheadline.weight(.semibold))
                Text(account.providerType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if account.isActive {
                Label("Active", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            } else {
                Button("Set Active") {
                    mailStore.setActiveAccount(account.id)
                    onAccountsChanged?()
                }
                .buttonStyle(.bordered)
            }

            Button(role: .destructive) {
                mailStore.removeAccount(account)
                onAccountsChanged?()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }

    private var connectProvidersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Connect New Provider", systemImage: "plus.circle.fill")
                .font(.headline)

            ForEach(providerOrder, id: \.self) { provider in
                providerButton(provider)
            }

            if expandedIMAP {
                imapForm
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    @ViewBuilder
    private func providerButton(_ provider: MailAccount.ProviderType) -> some View {
        Button {
            Task { await handleTap(provider) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: providerIcon(provider))
                    .font(.headline)
                    .foregroundStyle(providerColor(provider))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(providerSubtitle(provider))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if loadingProvider == provider {
                    ProgressView()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(loadingProvider != nil)
    }

    private var imapForm: some View {
        VStack(spacing: 10) {
            field("IMAP Host", text: $imapHost)
            field("IMAP Port", text: $imapPort)
            field("SMTP Host", text: $smtpHost)
            field("SMTP Port", text: $smtpPort)
            field("Username / Email", text: $imapUser)
            secureField("Password", text: $imapPassword)

            Button {
                Task { await connectIMAP() }
            } label: {
                HStack {
                    if loadingProvider == .imap {
                        ProgressView()
                    }
                    Text("Connect IMAP Account")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(loadingProvider != nil || imapHost.isEmpty || imapUser.isEmpty || imapPassword.isEmpty)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var protonGuideSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Proton Bridge Required")
                    .font(.title3.bold())

                Text("Install Proton Bridge and keep it running first. Then use your Bridge username/password in the IMAP fields and continue.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Install Proton Bridge")
                    Text("2. Sign in with your Proton account")
                    Text("3. Enter Bridge username/password in IMAP fields")
                    Text("4. Continue to connect")
                }
                .font(.subheadline)

                Spacer()

                Button("Continue") {
                    showProtonGuide = false
                    Task { await connectProtonBridge() }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .navigationTitle("Proton Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { showProtonGuide = false }
                }
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func secureField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
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
        case .imap: return Color(hex: "#8A8AA5") ?? .gray
        case .icloud: return .blue
        }
    }

    private func providerSubtitle(_ provider: MailAccount.ProviderType) -> String {
        switch provider {
        case .gmail: return "Google OAuth"
        case .outlook: return "Microsoft OAuth"
        case .yahoo: return "Yahoo OAuth"
        case .proton: return "Proton Bridge"
        case .imap: return "Manual server setup"
        case .icloud: return "Apple Mail"
        }
    }

    private func handleTap(_ provider: MailAccount.ProviderType) async {
        if provider == .imap {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedIMAP.toggle()
            }
            return
        }

        if provider == .proton {
            showProtonGuide = true
            return
        }

        loadingProvider = provider
        defer { loadingProvider = nil }

        do {
            let session: MailSession
            switch provider {
            case .gmail:
                session = try await GmailProvider().authenticate(credentials: .oauth())
            case .outlook:
                session = try await OutlookProvider().authenticate(credentials: .oauth())
            case .yahoo:
                session = try await YahooMailProvider().authenticate(credentials: .oauth())
            case .proton, .imap, .icloud:
                return
            }

            _ = await MainActor.run { AccountManager.shared.addAccount(session) }
            onAccountsChanged?()
            mailStore.reloadAccounts()
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func connectProtonBridge() async {
        loadingProvider = .proton
        defer { loadingProvider = nil }

        guard !imapUser.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !imapPassword.isEmpty else {
            showError("Enter your Proton Bridge username and password in IMAP fields first.")
            return
        }

        do {
            let credentials = MailCredentials(
                email: imapUser.trimmingCharacters(in: .whitespacesAndNewlines),
                password: imapPassword,
                host: "127.0.0.1",
                port: 1143,
                smtpHost: "127.0.0.1",
                smtpPort: 1025,
                accessToken: nil,
                refreshToken: nil
            )
            let session = try await ProtonMailProvider().authenticate(credentials: credentials)
            _ = MailKeychainManager.shared.saveCredentials(email: session.email, password: imapPassword)
            _ = await MainActor.run { AccountManager.shared.addAccount(session) }
            onAccountsChanged?()
            mailStore.reloadAccounts()
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

            _ = await MainActor.run { AccountManager.shared.addAccount(session) }
            onAccountsChanged?()
            mailStore.reloadAccounts()
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String) {
        withAnimation {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
}

#Preview {
    ManageAccountsView()
}
