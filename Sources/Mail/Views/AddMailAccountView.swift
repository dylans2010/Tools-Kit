import SwiftUI

struct AddMailAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var onAccountSelected: ((MailAccount) -> Void)? = nil

    @StateObject private var mailStore = MailStore.shared

    @State private var stagedButtons: Set<MailAccount.ProviderType> = []
    @State private var loadingProvider: MailAccount.ProviderType?
    @State private var toastMessage: String?
    @State private var signedInAccount: MailAccount?
    @State private var showProtonGuide = false

    @State private var imapHost = ""
    @State private var imapPort = "993"
    @State private var smtpHost = ""
    @State private var smtpPort = "465"
    @State private var imapUser = ""
    @State private var imapPassword = ""
    @State private var expandedIMAP = false

    private let buttonOrder: [MailAccount.ProviderType] = [.gmail, .outlook, .yahoo, .proton, .imap]

    var body: some View {
        NavigationStack {
            ZStack {
                (Color(hex: "#0A0A0F") ?? .black)
                    .ignoresSafeArea()

                AnimatedMeshBackground()
                    .ignoresSafeArea()
                    .opacity(0.15)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 22) {
                        header
                            .padding(.top, 42)

                        VStack(spacing: 14) {
                            providerButton(.gmail, title: "Continue with Gmail", icon: "g.circle.fill")
                            providerButton(.outlook, title: "Continue with Outlook", icon: "o.circle.fill")
                            providerButton(.yahoo, title: "Continue with Yahoo Mail", icon: "y.circle.fill")
                            providerButton(.proton, title: "Continue with Proton Mail", icon: "lock.shield.fill")
                            imapButton
                        }
                        .padding(.top, 4)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }

                if let toastMessage {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.85), in: Capsule())
                            .padding(.bottom, 22)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.86), value: toastMessage)
            .navigationBarHidden(true)
            .navigationDestination(
                isPresented: Binding(
                    get: { signedInAccount != nil },
                    set: { isPresented in
                        if !isPresented {
                            signedInAccount = nil
                        }
                    }
                )
            ) {
                if let account = signedInAccount {
                    InboxView(account: account, folder: .inbox)
                }
            }
            .sheet(isPresented: $showProtonGuide) {
                protonGuideSheet
            }
            .onAppear {
                mailStore.reloadAccounts()
                if let active = mailStore.activeAccount {
                    signedInAccount = active
                }

                for (idx, provider) in buttonOrder.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + (Double(idx) * 0.11)) {
                        stagedButtons.insert(provider)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.4))
                    .blur(radius: 34)
                    .frame(width: 144, height: 144)

                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 74, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.white, Color(hex: "#BFBFFF") ?? .white], startPoint: .top, endPoint: .bottom)
                    )
            }
            .frame(height: 150)

            Text("Your inbox, unified.")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Connect your accounts to get started")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(hex: "#9A9AAF") ?? .gray)
        }
    }

    @ViewBuilder
    private func providerButton(_ provider: MailAccount.ProviderType, title: String, icon: String) -> some View {
        Button {
            Task { await handleTap(provider) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(providerBrandColor(provider))
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "#A8A8C0") ?? .gray)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                if loadingProvider == provider {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#1A1A26") ?? .black, in: Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.6)
            )
        }
        .buttonStyle(.plain)
        .disabled(loadingProvider != nil)
        .opacity(stagedButtons.contains(provider) ? 1 : 0)
        .offset(y: stagedButtons.contains(provider) ? 0 : 24)
        .animation(.easeOut(duration: 0.42), value: stagedButtons)
    }

    private var imapButton: some View {
        VStack(spacing: 12) {
            providerButton(.imap, title: "Continue with IMAP / Other", icon: "server.rack")

            if expandedIMAP {
                VStack(spacing: 10) {
                    Group {
                        darkField("IMAP Host", text: $imapHost)
                        darkField("IMAP Port", text: $imapPort)
                        darkField("SMTP Host", text: $smtpHost)
                        darkField("SMTP Port", text: $smtpPort)
                        darkField("Username / Email", text: $imapUser)
                        darkSecureField("Password", text: $imapPassword)
                    }

                    Button {
                        Task { await connectIMAP() }
                    } label: {
                        HStack {
                            if loadingProvider == .imap {
                                ProgressView().tint(.white)
                            }
                            Text("Connect IMAP Account")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#2A2A3A") ?? .black, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(loadingProvider != nil || imapHost.isEmpty || imapUser.isEmpty || imapPassword.isEmpty)
                }
                .padding(14)
                .background(Color(hex: "#141420") ?? .black, in: RoundedRectangle(cornerRadius: 16))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .opacity(stagedButtons.contains(.imap) ? 1 : 0)
        .offset(y: stagedButtons.contains(.imap) ? 0 : 24)
        .animation(.easeOut(duration: 0.42), value: stagedButtons)
    }

    private var protonGuideSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Proton Bridge Required")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("To connect Proton Mail, install Proton Bridge and keep it running on this device first.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#B0B0C8") ?? .gray)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Install Proton Bridge")
                    Text("2. Sign in to your Proton account in Bridge")
                    Text("3. Copy bridge username/password")
                    Text("4. Tap Continue to connect via 127.0.0.1:1143")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

                Spacer()

                Button("Continue") {
                    showProtonGuide = false
                    Task { await connectProtonBridge() }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "#2A3D31") ?? .black, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0D0D14") ?? .black)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { showProtonGuide = false }
                }
            }
        }
    }

    private func darkField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: "#1A1A26") ?? .black, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
    }

    private func darkSecureField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: "#1A1A26") ?? .black, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
    }

    private func providerBrandColor(_ provider: MailAccount.ProviderType) -> Color {
        switch provider {
        case .gmail: return Color(hex: "#EA4335") ?? .red
        case .outlook: return Color(hex: "#0078D4") ?? .blue
        case .yahoo: return Color(hex: "#6C3BD1") ?? .purple
        case .proton: return Color(hex: "#2E8B57") ?? .green
        case .imap: return Color(hex: "#8A8AA5") ?? .gray
        case .icloud: return .blue
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

            let account = await MainActor.run { AccountManager.shared.addAccount(session) }
            onAccountSelected?(account)
            signedInAccount = account
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
            let account = await MainActor.run { AccountManager.shared.addAccount(session) }
            onAccountSelected?(account)
            signedInAccount = account
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
            signedInAccount = account
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }

}

private struct AnimatedMeshBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let w = size.width
                let h = size.height

                let p1 = CGPoint(x: w * (0.25 + 0.1 * sin(t * 0.08)), y: h * (0.28 + 0.08 * cos(t * 0.06)))
                let p2 = CGPoint(x: w * (0.72 + 0.12 * cos(t * 0.07)), y: h * (0.35 + 0.07 * sin(t * 0.05)))
                let p3 = CGPoint(x: w * (0.50 + 0.12 * sin(t * 0.04)), y: h * (0.75 + 0.08 * cos(t * 0.08)))

                context.fill(Path(ellipseIn: CGRect(x: p1.x - 160, y: p1.y - 160, width: 320, height: 320)), with: .color((Color(hex: "#6F4CFF") ?? .indigo).opacity(0.45)))
                context.fill(Path(ellipseIn: CGRect(x: p2.x - 180, y: p2.y - 180, width: 360, height: 360)), with: .color((Color(hex: "#4E7BFF") ?? .blue).opacity(0.40)))
                context.fill(Path(ellipseIn: CGRect(x: p3.x - 190, y: p3.y - 190, width: 380, height: 380)), with: .color((Color(hex: "#4338CA") ?? .purple).opacity(0.38)))
            }
            .blur(radius: 78)
        }
    }
}

#Preview {
    AddMailAccountView()
        .preferredColorScheme(.dark)
}
