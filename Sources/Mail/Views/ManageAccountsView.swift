import SwiftUI

struct ManageAccountsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mailStore = MailStore.shared
    @State private var loadingProvider: MailAccount.ProviderType?
    @State private var statusMessage: String?
    @State private var isSuccess = false
    @State private var showError = false

    var onSelectAccount: ((MailAccount) -> Void)?

    init(onSelectAccount: ((MailAccount) -> Void)? = nil) {
        self.onSelectAccount = onSelectAccount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -150, y: -200)

                ScrollView {
                    VStack(spacing: 32) {
                        connectedAccountsList

                        VStack(alignment: .leading, spacing: 20) {
                            Text("Connect New Provider")
                                .font(.title3.bold())
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(MailAccount.ProviderType.allCases, id: \.self) { provider in
                                    modernProviderCard(for: provider)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }

                if loadingProvider != nil {
                    loadingOverlay
                }

                if showError {
                    feedbackOverlay(message: statusMessage ?? "Unknown Error", isError: true)
                }

                if isSuccess {
                    feedbackOverlay(message: statusMessage ?? "Success", isError: false)
                }
            }
            .navigationTitle("Mail Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.bold())
                }
            }
        }
    }

    private var connectedAccountsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Accounts")
                .font(.title3.bold())
                .padding(.horizontal)

            if mailStore.accounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No Accounts Connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)
            } else {
                ForEach(mailStore.accounts) { account in
                    HStack(spacing: 16) {
                        providerIconView(for: account.providerType)
                            .scaleEffect(1.2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.emailAddress)
                                .font(.subheadline.bold())
                            Text(account.providerType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if account.isActive {
                            Text("Active")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15), in: Capsule())
                                .foregroundStyle(.green)
                        }

                        Menu {
                            Button {
                                onSelectAccount?(account)
                                dismiss()
                            } label: {
                                Label("Select", systemImage: "checkmark.circle")
                            }

                            Button(role: .destructive) {
                                withAnimation {
                                    mailStore.removeAccount(account)
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .bold))
                                .padding(8)
                                .background(Color.white.opacity(0.1), in: Circle())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .padding(.horizontal)
                }
            }
        }
    }

    private func modernProviderCard(for provider: MailAccount.ProviderType) -> some View {
        Button {
            Task { await handleProviderTap(provider) }
        } label: {
            VStack(spacing: 12) {
                providerIconView(for: provider)
                Text(provider.displayName)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func providerIconView(for provider: MailAccount.ProviderType) -> some View {
        ZStack {
            Circle()
                .fill(providerColor(provider).opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: providerIcon(for: provider))
                .foregroundStyle(providerColor(provider))
                .font(.system(size: 20, weight: .semibold))
        }
    }

    private func providerIcon(for provider: MailAccount.ProviderType) -> String {
        switch provider {
        case .gmail: return "g.circle.fill"
        case .outlook: return "envelope.fill"
        case .yahoo: return "y.circle.fill"
        case .icloud: return "icloud.fill"
        default: return "envelope.badge.shield.half.filled"
        }
    }

    private func providerColor(_ provider: MailAccount.ProviderType) -> Color {
        switch provider {
        case .gmail: return .red
        case .outlook: return .blue
        case .yahoo: return .purple
        case .proton: return .green
        case .icloud: return .cyan
        case .imap: return .gray
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                Text("Authenticating...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private func feedbackOverlay(message: String, isError: Bool) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: isError ? "xmark.octagon.fill" : "checkmark.seal.fill")
                    .foregroundStyle(isError ? Color.red : Color.green)
                    .font(.headline)

                Text(message)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isError ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1.5))
            .padding(.bottom, 40)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .ignoresSafeArea()
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
                triggerFeedback(message: "Account Connected Successfully!", error: false)
            }
        } catch {
            await MainActor.run {
                loadingProvider = nil
                triggerFeedback(message: "Failed To Connect: \(error.localizedDescription)", error: true)
            }
        }
    }

    private func triggerFeedback(message: String, error: Bool) {
        statusMessage = message
        if error {
            withAnimation(.spring()) { showError = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { showError = false }
            }
        } else {
            withAnimation(.spring()) { isSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { isSuccess = false }
            }
        }
    }
}
