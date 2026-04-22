import SwiftUI

struct UniversalInboxView: View {
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var storage = MailStorageService.shared
    @StateObject private var sync = MailSyncService.shared

    @AppStorage("mail.universal.expandedAccount") private var expandedAccountId: String = ""
    @AppStorage("mail.universal.grouping") private var groupingMode: String = "account"
    @AppStorage("mail.settings.defaultSenderAccountId") private var defaultSenderAccountId: String = ""

    @State private var selectedFolderByAccount: [String: String] = [:]
    @State private var customFoldersByAccount: [String: [String]] = [:]
    @State private var assignmentByAccount: [String: [String: String]] = [:]
    @State private var showFolderEditorForAccount: MailAccount?
    @State private var selectedMessage: MailMessage?
    @State private var showMailSettings = false
    @State private var navigationTarget: InboxNavigationTarget?
    @State private var didAutoOpenDefaultInbox = false

    var body: some View {
        List {
            headerSection
            if isUnifiedMode {
                unifiedFeedSection
            } else {
                accountSections
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.08, blue: 0.14), Color(red: 0.09, green: 0.11, blue: 0.18), Color(red: 0.15, green: 0.08, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showMailSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(item: $showFolderEditorForAccount) { account in
            FolderEditorSheet(
                account: account,
                folders: customFoldersByAccount[account.id] ?? [],
                onSave: { updated in
                    customFoldersByAccount[account.id] = updated
                    persistFolderState()
                }
            )
        }
        .sheet(isPresented: $showMailSettings) {
            MailSettingsView()
        }
        .task {
            accountManager.refreshAccounts()
            loadFolderState()
            await syncAll()
            autoOpenDefaultInboxIfNeeded()
        }
        .onChange(of: accountManager.accounts.map(\.id).joined(separator: ",")) { _ in
            loadFolderState()
            autoOpenDefaultInboxIfNeeded()
        }
        .navigationDestination(item: $navigationTarget) { destination in
            if let account = accountManager.account(for: destination.accountId) {
                InboxView(account: account, folder: destination.folder)
            }
        }
    }

    private var isUnifiedMode: Bool { groupingMode == "unified" }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Universal Inbox")
                            .font(.title2.bold())
                        Text("See every mailbox in one place or drill into each account.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        showMailSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.bordered)
                }

                Picker("View", selection: $groupingMode) {
                    Text("By Account").tag("account")
                    Text("Unified").tag("unified")
                }
                .pickerStyle(.segmented)

                HStack(spacing: 10) {
                    statusPill(title: "Accounts", value: "\(accountManager.accounts.count)", systemImage: "person.2")
                    statusPill(title: "Mode", value: isUnifiedMode ? "Unified" : "Split", systemImage: isUnifiedMode ? "rectangle.3.group" : "person.crop.circle")
                    Spacer(minLength: 0)
                    Button {
                        Task { await syncAll() }
                    } label: {
                        HStack(spacing: 8) {
                            Text(sync.isSyncing ? "Syncing…" : "Sync All")
                            if sync.isSyncing { ProgressView() }
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var accountSections: some View {
        ForEach(accountManager.accounts) { account in
            Section {
                accountHeader(account)
                if expandedAccountId == account.id {
                    folderPicker(account)
                    threadsFor(account)
                }
            }
        }
    }

    private var unifiedFeedSection: some View {
        Section("All Accounts") {
            ForEach(unifiedMessages()) { mail in
                messageRow(mail, account: accountManager.account(for: mail.accountId))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openInbox(accountId: mail.accountId, folderName: mappedFolder(for: mail.message.id, accountId: mail.accountId))
                    }
            }
        }
    }

    private func accountHeader(_ account: MailAccount) -> some View {
        HStack(spacing: 12) {
            Button {
                openInbox(for: account, folderName: selectedFolder(for: account))
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(providerColor(account.providerType).opacity(0.18))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: providerIcon(account.providerType))
                                .font(.body.weight(.bold))
                                .foregroundStyle(providerColor(account.providerType))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.emailAddress)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text("\(account.providerType.displayName) • \(selectedFolder(for: account))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                toggleAccountSection(account)
            } label: {
                Image(systemName: expandedAccountId == account.id ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func folderPicker(_ account: MailAccount) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(allFolders(for: account), id: \.self) { folder in
                        let selected = selectedFolder(for: account) == folder
                        Text(folder)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(selected ? Color.accentColor.opacity(0.24) : Color.secondary.opacity(0.15), in: Capsule())
                            .onTapGesture {
                                selectedFolderByAccount[account.id] = folder
                                openInbox(for: account, folderName: folder)
                            }
                    }
                }
            }

            Button("Manage Custom Folders") {
                showFolderEditorForAccount = account
            }
            .font(.caption)
        }
    }

    private func threadsFor(_ account: MailAccount) -> some View {
        let folder = selectedFolder(for: account)
        let key = "\(account.id)_INBOX"
        let rows = storage.loadThreads(for: key)
            .flatMap(\.messages)
            .filter { mappedFolder(for: $0.id, accountId: account.id) == folder }
            .sorted { $0.date > $1.date }

        return AnyView(
            ForEach(rows) { message in
                let scoped = ScopedMailMessage(accountId: account.id, message: message)
                messageRow(scoped, account: account)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openInbox(for: account, folderName: mappedFolder(for: scoped.message.id, accountId: scoped.accountId))
                    }
            }
        )
    }

    private func messageRow(_ scoped: ScopedMailMessage, account: MailAccount?) -> some View {
        HStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Text(senderInitials(scoped.message.from))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    )

                if !scoped.message.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(senderName(scoped.message.from))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(scoped.message.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(scoped.message.subject)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(previewText(scoped.message))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let account {
                    Text("\(account.providerType.displayName) • \(account.emailAddress)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                toggleImportant(scoped)
            } label: { Label("Important", systemImage: "flag") }
            .tint(.orange)

            Button {
                markRead(scoped)
            } label: { Label("Read", systemImage: "envelope.open") }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Menu {
                ForEach(allFolders(forAccountId: scoped.accountId), id: \.self) { folder in
                    Button(folder) { moveMessage(scoped, to: folder) }
                }
            } label: {
                Label("Move", systemImage: "folder")
            }

            Button(role: .destructive) {
                delete(scoped)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                archive(scoped)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(.gray)
        }
    }

    private func selectedFolder(for account: MailAccount) -> String {
        selectedFolderByAccount[account.id] ?? "Inbox"
    }

    private func allFolders(for account: MailAccount) -> [String] {
        allFolders(forAccountId: account.id)
    }

    private func allFolders(forAccountId accountId: String) -> [String] {
        ["Inbox", "Sent", "Archive", "Deleted", "Important"] + (customFoldersByAccount[accountId] ?? [])
    }

    private func mappedFolder(for messageId: String, accountId: String) -> String {
        assignmentByAccount[accountId]?[messageId] ?? "Inbox"
    }

    private func moveMessage(_ scoped: ScopedMailMessage, to folder: String) {
        var map = assignmentByAccount[scoped.accountId] ?? [:]
        map[scoped.message.id] = folder
        assignmentByAccount[scoped.accountId] = map
        persistFolderState()
    }

    private func toggleImportant(_ scoped: ScopedMailMessage) {
        moveMessage(scoped, to: "Important")
    }

    private func archive(_ scoped: ScopedMailMessage) {
        moveMessage(scoped, to: "Archive")
    }

    private func delete(_ scoped: ScopedMailMessage) {
        moveMessage(scoped, to: "Deleted")
        Task {
            guard let account = accountManager.account(for: scoped.accountId) else { return }
            try? await deleteRemote(messageId: scoped.message.id, account: account)
        }
    }

    private func markRead(_ scoped: ScopedMailMessage) {
        Task {
            guard let account = accountManager.account(for: scoped.accountId) else { return }
            try? await markReadRemote(messageId: scoped.message.id, account: account)
        }
    }

    private func unifiedMessages() -> [ScopedMailMessage] {
        accountManager.accounts
            .flatMap { account in
                let key = "\(account.id)_INBOX"
                return storage.loadThreads(for: key)
                    .flatMap(\.messages)
                    .map { ScopedMailMessage(accountId: account.id, message: $0) }
            }
            .sorted { $0.message.date > $1.message.date }
    }

    private func syncAll() async {
        for account in accountManager.accounts {
            await MailSyncService.shared.fetchThreads(account: account, folder: .inbox)
        }
    }

    private func persistFolderState() {
        let state = FolderState(customFoldersByAccount: customFoldersByAccount, assignmentByAccount: assignmentByAccount)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "mail.universal.folders")
        }
    }

    private func loadFolderState() {
        guard let data = UserDefaults.standard.data(forKey: "mail.universal.folders"),
              let state = try? JSONDecoder().decode(FolderState.self, from: data) else { return }
        customFoldersByAccount = state.customFoldersByAccount
        assignmentByAccount = state.assignmentByAccount
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
        case .gmail: return .red
        case .outlook: return .blue
        case .yahoo: return .purple
        case .proton: return .green
        case .imap, .icloud: return .gray
        }
    }

    private func senderName(_ raw: String) -> String {
        if let index = raw.firstIndex(of: "<") {
            return String(raw[..<index]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return raw
    }

    private func senderInitials(_ sender: String) -> String {
        let parts = senderName(sender).split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }

    private func previewText(_ message: MailMessage) -> String {
        let base = message.body.isEmpty ? (message.htmlBody ?? "") : message.body
        return base
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func statusPill(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func toggleAccountSection(_ account: MailAccount) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedAccountId = expandedAccountId == account.id ? "" : account.id
            accountManager.setActiveAccount(account.id)
        }
    }

    private func openInbox(for account: MailAccount, folderName: String = "Inbox") {
        accountManager.setActiveAccount(account.id)
        navigationTarget = InboxNavigationTarget(accountId: account.id, folder: mailFolder(for: folderName))
    }

    private func openInbox(accountId: String, folderName: String = "Inbox") {
        guard let account = accountManager.account(for: accountId) else { return }
        openInbox(for: account, folderName: folderName)
    }

    private func autoOpenDefaultInboxIfNeeded() {
        guard !didAutoOpenDefaultInbox, navigationTarget == nil else { return }
        guard !isUnifiedMode else { return }

        let preferredAccountId: String? = {
            if !defaultSenderAccountId.isEmpty,
               accountManager.account(for: defaultSenderAccountId) != nil {
                return defaultSenderAccountId
            }
            if let activeId = accountManager.activeAccount?.id,
               accountManager.account(for: activeId) != nil {
                return activeId
            }
            return accountManager.accounts.first?.id
        }()

        guard let preferredAccountId else { return }
        didAutoOpenDefaultInbox = true
        openInbox(accountId: preferredAccountId, folderName: "Inbox")
    }

    private func mailFolder(for name: String) -> MailFolder {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalized.lowercased() {
        case "sent":
            return .sent
        case "drafts":
            return .drafts
        case "important", "starred":
            return MailFolder(id: "STARRED", name: "Important", type: .starred)
        case "deleted", "trash":
            return .trash
        case "archive":
            return MailFolder(id: "ARCHIVE", name: "Archive", type: .custom)
        case "inbox", "":
            return .inbox
        default:
            return MailFolder(id: normalized.uppercased(), name: normalized, type: .custom)
        }
    }

    private func providerSession(for account: MailAccount) -> MailSession {
        MailSession(id: account.id, provider: account.providerType, email: account.emailAddress, displayName: account.displayName, accessTokenExpiration: account.accessTokenExpiration, imapHost: account.imapHost, imapPort: account.imapPort, smtpHost: account.smtpHost, smtpPort: account.smtpPort)
    }

    private func deleteRemote(messageId: String, account: MailAccount) async throws {
        switch account.providerType {
        case .gmail: try await GmailProvider().deleteMessage(session: providerSession(for: account), id: messageId)
        case .outlook: try await OutlookProvider().deleteMessage(session: providerSession(for: account), id: messageId)
        case .yahoo: try await YahooMailProvider().deleteMessage(session: providerSession(for: account), id: messageId)
        case .proton: try await ProtonMailProvider().deleteMessage(session: providerSession(for: account), id: messageId)
        case .imap, .icloud: try await IMAPProvider().deleteMessage(session: providerSession(for: account), id: messageId)
        }
    }

    private func markReadRemote(messageId: String, account: MailAccount) async throws {
        switch account.providerType {
        case .gmail: try await GmailProvider().markRead(session: providerSession(for: account), id: messageId)
        case .outlook: try await OutlookProvider().markRead(session: providerSession(for: account), id: messageId)
        case .yahoo: try await YahooMailProvider().markRead(session: providerSession(for: account), id: messageId)
        case .proton: try await ProtonMailProvider().markRead(session: providerSession(for: account), id: messageId)
        case .imap, .icloud: try await IMAPProvider().markRead(session: providerSession(for: account), id: messageId)
        }
    }
}

private struct InboxNavigationTarget: Identifiable, Hashable {
    let accountId: String
    let folder: MailFolder

    var id: String { "\(accountId)_\(folder.id)" }
}

private struct ScopedMailMessage: Identifiable {
    let accountId: String
    let message: MailMessage

    var id: String { "\(accountId)_\(message.id)" }
}

private struct FolderState: Codable {
    var customFoldersByAccount: [String: [String]]
    var assignmentByAccount: [String: [String: String]]
}

private struct FolderEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let account: MailAccount
    @State var folders: [String]
    let onSave: ([String]) -> Void

    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Custom folders") {
                    ForEach(Array(folders.enumerated()), id: \.offset) { index, item in
                        TextField("Folder", text: Binding(
                            get: { folders[index] },
                            set: { folders[index] = $0 }
                        ))
                    }
                    .onDelete { offsets in
                        folders.remove(atOffsets: offsets)
                    }
                }

                Section("Create") {
                    TextField("New folder", text: $newName)
                    Button("Add") {
                        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        folders.append(trimmed)
                        newName = ""
                    }
                }
            }
            .navigationTitle(account.emailAddress)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(folders.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
                        dismiss()
                    }
                }
            }
        }
    }
}
