import SwiftUI

struct UniversalInboxView: View {
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var storage = MailStorageService.shared
    @StateObject private var sync = MailSyncService.shared

    @AppStorage("mail.universal.expandedAccount") private var expandedAccountId: String = ""
    @AppStorage("mail.universal.grouping") private var groupingMode: String = "account"

    @State private var selectedFolderByAccount: [String: String] = [:]
    @State private var customFoldersByAccount: [String: [String]] = [:]
    @State private var assignmentByAccount: [String: [String: String]] = [:]
    @State private var showFolderEditorForAccount: MailAccount?
    @State private var selectedMessage: MailMessage?
    @State private var showMailSettings = false
    @State private var navigationTarget: InboxNavigationTarget?

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
        .navigationTitle("Universal Inbox")
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
        }
        .onChange(of: accountManager.accounts.map(\.id).joined(separator: ",")) { _ in
            loadFolderState()
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
            Picker("View", selection: $groupingMode) {
                Text("By Account").tag("account")
                Text("Unified").tag("unified")
            }
            .pickerStyle(.segmented)

            Button {
                Task { await syncAll() }
            } label: {
                HStack {
                    Text(sync.isSyncing ? "Syncing…" : "Sync All Accounts")
                    Spacer()
                    if sync.isSyncing { ProgressView() }
                }
            }
        }
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
                Label(account.emailAddress, systemImage: providerIcon(account.providerType))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                toggleAccountSection(account)
            } label: {
                Image(systemName: expandedAccountId == account.id ? "chevron.up" : "chevron.down")
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
        }
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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(scoped.message.subject)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(scoped.message.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(scoped.message.from)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
