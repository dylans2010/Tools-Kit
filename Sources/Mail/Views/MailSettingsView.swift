import SwiftUI

struct MailSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var accountManager = AccountManager.shared

    @AppStorage("mail.settings.undoSendEnabled") private var undoSendEnabled = true
    @AppStorage("mail.settings.undoSendDelay") private var undoSendDelay = 10
    @AppStorage("mail.settings.defaultSenderAccountId") private var defaultSenderAccountId = ""

    @AppStorage("mail.settings.unifiedInbox") private var unifiedInboxEnabled = true
    @AppStorage("mail.settings.threadedConversations") private var threadedConversationsEnabled = true
    @AppStorage("mail.settings.sortOrder") private var sortOrder = "newest"
    @AppStorage("mail.settings.showAvatars") private var showAvatars = true
    @AppStorage("mail.settings.showAttachmentIndicators") private var showAttachmentIndicators = true
    @AppStorage("mail.settings.previewLines") private var previewLines = 2

    @AppStorage("mail.settings.defaultArchiveFolder") private var defaultArchiveFolder = "Archive"
    @AppStorage("mail.settings.defaultDeleteBehavior") private var defaultDeleteBehavior = "Move to Trash"
    @AppStorage("mail.settings.autoSortEmails") private var autoSortEmails = false
    @AppStorage("mail.settings.autoMarkImportant") private var autoMarkImportant = false

    @AppStorage("mail.settings.importantOnlyNotifications") private var importantOnlyNotifications = false
    @AppStorage("mail.settings.showNotificationPreviews") private var showNotificationPreviews = true

    @AppStorage("mail.settings.autoSync") private var autoSyncEnabled = true
    @AppStorage("mail.settings.syncInterval") private var syncInterval = "15 min"
    @AppStorage("mail.settings.autoDownloadAttachments") private var autoDownloadAttachments = false

    @AppStorage("mail.settings.requireBiometrics") private var requireBiometrics = false
    @AppStorage("mail.settings.hidePreviewsWhenLocked") private var hidePreviewsWhenLocked = true
    @AppStorage("mail.settings.blockRemoteImages") private var blockRemoteImages = false

    @AppStorage("mail.settings.ai.autoSummarize") private var autoSummarizeEmails = true
    @AppStorage("mail.settings.ai.smartReply") private var smartReplySuggestions = true
    @AppStorage("mail.settings.ai.autoCategorize") private var autoCategorizeEmails = true

    @State private var signatures: [String: String] = [:]
    @State private var notificationByAccount: [String: Bool] = [:]

    @State private var showManageAccounts = false
    @State private var showAdvanced = false
    @State private var showResetConfirmation = false

    private let undoSendDurations = [5, 10, 20, 30]
    private let sortOptions = ["Newest first", "Oldest first"]
    private let archiveOptions = ["Archive", "All Mail", "Inbox"]
    private let deleteOptions = ["Move to Trash", "Archive Instead", "Delete Permanently"]
    private let syncOptions = ["Manual", "5 min", "15 min"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    sectionCard(title: "Account Management", icon: "person.2.crop.square.stack") {
                        Button {
                            showManageAccounts = true
                        } label: {
                            HStack {
                                Label("Manage Accounts", systemImage: "person.crop.circle.badge.gearshape")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        if accountManager.accounts.isEmpty {
                            Text("No connected accounts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                        } else {
                            ForEach(accountManager.accounts) { account in
                                HStack(spacing: 10) {
                                    Image(systemName: providerIcon(account.providerType))
                                        .foregroundStyle(providerColor(account.providerType))
                                        .frame(width: 28, height: 28)
                                        .background(providerColor(account.providerType).opacity(0.18), in: Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(account.emailAddress)
                                            .font(.subheadline.weight(.semibold))
                                            .lineLimit(1)
                                        Text(statusText(for: account))
                                            .font(.caption)
                                            .foregroundStyle(statusColor(for: account))
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                    sectionCard(title: "Sending Settings", icon: "paperplane") {
                        Toggle("Undo Send", isOn: $undoSendEnabled)
                            .tint(.cyan)

                        Picker("Undo delay", selection: $undoSendDelay) {
                            ForEach(undoSendDurations, id: \.self) { duration in
                                Text("\(duration) seconds").tag(duration)
                            }
                        }
                        .disabled(!undoSendEnabled)

                        Picker("Default account", selection: $defaultSenderAccountId) {
                            ForEach(accountManager.accounts) { account in
                                Text("\(account.displayName) (\(account.emailAddress))").tag(account.id)
                            }
                        }

                        if accountManager.accounts.isEmpty {
                            Text("Connect an account to set a default sender.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Signatures")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ForEach(accountManager.accounts) { account in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(account.emailAddress)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("Signature", text: Binding(
                                        get: { signatures[account.id] ?? "" },
                                        set: { value in
                                            signatures[account.id] = value
                                            saveSignatures()
                                        }
                                    ), axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    }

                    sectionCard(title: "Inbox Behavior", icon: "tray.full") {
                        Toggle("Unified Inbox", isOn: $unifiedInboxEnabled).tint(.cyan)
                        Toggle("Threaded Conversations", isOn: $threadedConversationsEnabled).tint(.cyan)

                        Picker("Sort", selection: $sortOrder) {
                            ForEach(sortOptions, id: \.self) { option in
                                Text(option).tag(option == "Newest first" ? "newest" : "oldest")
                            }
                        }

                        Toggle("Show avatars", isOn: $showAvatars).tint(.cyan)
                        Toggle("Show attachment indicators", isOn: $showAttachmentIndicators).tint(.cyan)

                        Picker("Preview lines", selection: $previewLines) {
                            ForEach(1...3, id: \.self) { lineCount in
                                Text("\(lineCount)").tag(lineCount)
                            }
                        }
                    }

                    sectionCard(title: "Folder + Organization", icon: "folder") {
                        Picker("Default archive folder", selection: $defaultArchiveFolder) {
                            ForEach(archiveOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }

                        Picker("Delete behavior", selection: $defaultDeleteBehavior) {
                            ForEach(deleteOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }

                        Toggle("Auto-sort emails", isOn: $autoSortEmails).tint(.cyan)
                        Toggle("Auto-mark important emails", isOn: $autoMarkImportant).tint(.cyan)
                    }

                    sectionCard(title: "Notifications", icon: "bell.badge") {
                        ForEach(accountManager.accounts) { account in
                            Toggle(account.emailAddress, isOn: Binding(
                                get: { notificationByAccount[account.id] ?? true },
                                set: { value in
                                    notificationByAccount[account.id] = value
                                    saveNotifications()
                                }
                            ))
                            .tint(.cyan)
                        }

                        Toggle("Important-only notifications", isOn: $importantOnlyNotifications).tint(.cyan)
                        Toggle("Show preview", isOn: $showNotificationPreviews).tint(.cyan)
                    }

                    sectionCard(title: "Performance + Sync", icon: "arrow.triangle.2.circlepath") {
                        Toggle("Auto-sync", isOn: $autoSyncEnabled).tint(.cyan)

                        Picker("Sync interval", selection: $syncInterval) {
                            ForEach(syncOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .disabled(!autoSyncEnabled)

                        Toggle("Download attachments automatically", isOn: $autoDownloadAttachments).tint(.cyan)

                        Button("Clear cache") {
                            clearCache()
                        }
                        .buttonStyle(.bordered)
                    }

                    sectionCard(title: "Privacy + Security", icon: "lock.shield") {
                        Toggle("Require Face ID / Touch ID", isOn: $requireBiometrics).tint(.cyan)
                        Toggle("Hide previews when locked", isOn: $hidePreviewsWhenLocked).tint(.cyan)
                        Toggle("Block remote images", isOn: $blockRemoteImages).tint(.cyan)
                    }

                    sectionCard(title: "AI Features", icon: "sparkles") {
                        Toggle("Auto summarize emails", isOn: $autoSummarizeEmails).tint(.cyan)
                        Toggle("Smart reply suggestions", isOn: $smartReplySuggestions).tint(.cyan)
                        Toggle("Auto categorize emails", isOn: $autoCategorizeEmails).tint(.cyan)

                        Text("Connected to DraftingEmails and TranslateEmail controls.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    sectionCard(title: "Debug / Advanced", icon: "wrench.and.screwdriver") {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAdvanced.toggle()
                            }
                        } label: {
                            HStack {
                                Text(showAdvanced ? "Hide advanced" : "Show advanced")
                                Spacer()
                                Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.plain)

                        if showAdvanced {
                            VStack(spacing: 10) {
                                Button("Force sync") {
                                    Task { await forceSync() }
                                }
                                .buttonStyle(.bordered)

                                Button("Reset email system", role: .destructive) {
                                    showResetConfirmation = true
                                }
                                .buttonStyle(.bordered)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Token status")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    ForEach(accountManager.accounts) { account in
                                        HStack {
                                            Text(account.emailAddress)
                                                .font(.caption)
                                            Spacer()
                                            Text(maskedTokenStatus(for: account))
                                                .font(.caption.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(14)
            }
            .background(
                LinearGradient(colors: [Color(hex: "#090A12") ?? .black, Color(hex: "#14152A") ?? .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Mail Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $showManageAccounts) {
                ManageAccountsView { selected in
                    accountManager.setActiveAccount(selected.id)
                    accountManager.refreshAccounts()
                    ensureValidDefaultAccount()
                }
            }
            .alert("Reset email system?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetEmailSystem()
                }
            } message: {
                Text("This clears cached mail and mail settings. Connected accounts remain intact.")
            }
            .onAppear {
                accountManager.refreshAccounts()
                loadSignatures()
                loadNotifications()
                ensureValidDefaultAccount()
            }
        }
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white)

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func providerIcon(_ provider: MailAccount.ProviderType) -> String {
        switch provider {
        case .gmail: return "envelope.badge"
        case .outlook: return "mail.stack"
        case .yahoo: return "mail.and.text.magnifyingglass"
        case .proton: return "lock.shield"
        case .imap, .icloud: return "tray.full"
        }
    }

    private func providerColor(_ provider: MailAccount.ProviderType) -> Color {
        switch provider {
        case .gmail: return Color(hex: "#EA4335") ?? .red
        case .outlook: return Color(hex: "#0078D4") ?? .blue
        case .yahoo: return Color(hex: "#6C3BD1") ?? .purple
        case .proton: return Color(hex: "#2E8B57") ?? .green
        case .imap, .icloud: return .cyan
        }
    }

    private func statusText(for account: MailAccount) -> String {
        let now = Date()
        if let expiration = account.accessTokenExpiration, expiration <= now {
            return "Expired"
        }

        if requiresOAuth(account.providerType) {
            let token = MailKeychainManager.shared.getOAuthTokens(accountId: account.id)?.accessToken
            return (token?.isEmpty == false) ? "Connected" : "Needs Re-auth"
        }

        let password = MailKeychainManager.shared.getPassword(for: account.emailAddress)
        return (password?.isEmpty == false) ? "Connected" : "Needs Re-auth"
    }

    private func statusColor(for account: MailAccount) -> Color {
        switch statusText(for: account) {
        case "Connected": return .green
        case "Expired": return .orange
        default: return .red
        }
    }

    private func requiresOAuth(_ provider: MailAccount.ProviderType) -> Bool {
        switch provider {
        case .gmail, .outlook, .yahoo, .proton:
            return true
        case .imap, .icloud:
            return false
        }
    }

    private func ensureValidDefaultAccount() {
        let ids = Set(accountManager.accounts.map(\.id))
        if !defaultSenderAccountId.isEmpty, ids.contains(defaultSenderAccountId) {
            return
        }
        defaultSenderAccountId = accountManager.activeAccount?.id ?? accountManager.accounts.first?.id ?? ""
    }

    private func forceSync() async {
        for account in accountManager.accounts {
            await MailSyncService.shared.fetchThreads(account: account, folder: .inbox)
        }
    }

    private func clearCache() {
        let fileManager = FileManager.default
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let mailDir = docs.appendingPathComponent("Workspace/Mail", isDirectory: true)

        guard let files = try? fileManager.contentsOfDirectory(at: mailDir, includingPropertiesForKeys: nil) else { return }
        for file in files where file.lastPathComponent.hasPrefix("threads_") {
            try? fileManager.removeItem(at: file)
        }
    }

    private func resetEmailSystem() {
        undoSendEnabled = true
        undoSendDelay = 10
        defaultSenderAccountId = accountManager.activeAccount?.id ?? accountManager.accounts.first?.id ?? ""

        unifiedInboxEnabled = true
        threadedConversationsEnabled = true
        sortOrder = "newest"
        showAvatars = true
        showAttachmentIndicators = true
        previewLines = 2

        defaultArchiveFolder = "Archive"
        defaultDeleteBehavior = "Move to Trash"
        autoSortEmails = false
        autoMarkImportant = false

        importantOnlyNotifications = false
        showNotificationPreviews = true

        autoSyncEnabled = true
        syncInterval = "15 min"
        autoDownloadAttachments = false

        requireBiometrics = false
        hidePreviewsWhenLocked = true
        blockRemoteImages = false

        autoSummarizeEmails = true
        smartReplySuggestions = true
        autoCategorizeEmails = true

        signatures = [:]
        notificationByAccount = [:]
        saveSignatures()
        saveNotifications()
        clearCache()
    }

    private func maskedTokenStatus(for account: MailAccount) -> String {
        if requiresOAuth(account.providerType) {
            guard let token = MailKeychainManager.shared.getOAuthTokens(accountId: account.id)?.accessToken,
                  !token.isEmpty else {
                return "No token"
            }
            return mask(token)
        }

        guard let password = MailKeychainManager.shared.getPassword(for: account.emailAddress), !password.isEmpty else {
            return "No credential"
        }
        return mask(password)
    }

    private func mask(_ value: String) -> String {
        guard value.count > 8 else { return String(repeating: "•", count: value.count) }
        let prefix = value.prefix(4)
        let suffix = value.suffix(4)
        return "\(prefix)••••\(suffix)"
    }

    private func loadSignatures() {
        signatures = MailSettingsPersistence.loadDictionary(forKey: "mail.settings.signatures")
    }

    private func saveSignatures() {
        MailSettingsPersistence.saveDictionary(signatures, forKey: "mail.settings.signatures")
    }

    private func loadNotifications() {
        notificationByAccount = MailSettingsPersistence.loadBoolDictionary(forKey: "mail.settings.notificationsByAccount")
    }

    private func saveNotifications() {
        MailSettingsPersistence.saveBoolDictionary(notificationByAccount, forKey: "mail.settings.notificationsByAccount")
    }
}

enum MailSettingsPersistence {
    static func loadDictionary(forKey key: String) -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return decoded
    }

    static func saveDictionary(_ value: [String: String], forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func loadBoolDictionary(forKey key: String) -> [String: Bool] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return [:]
        }
        return decoded
    }

    static func saveBoolDictionary(_ value: [String: Bool], forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
