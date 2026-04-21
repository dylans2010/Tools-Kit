import SwiftUI
import WebKit
import UIKit

struct InboxView: View {
    let account: MailAccount
    let folder: MailFolder
    var filter: InboxFilter = .all

    enum InboxFilter {
        case all, unread
    }

    @StateObject private var storage = MailStorageService.shared
    @StateObject private var mailStore = MailStore.shared
    @StateObject private var viewModel = InboxScreenViewModel()

    @State private var searchText = ""
    @State private var showingCompose = false
    @State private var showingAIFeatures = false
    @State private var showingUniversalInbox = false
    @State private var showingFetchingLabel = false
    @State private var selectedMessage: MailMessage?
    @State private var actionError: String?
    @State private var selectedCategory: InboxCategory = .all

    @AppStorage("mail.settings.swipe.leading") private var leadingSwipeAction = "flag"
    @AppStorage("mail.settings.swipe.trailing") private var trailingSwipeAction = "delete"
    @AppStorage("mail.settings.contextMenu.enabled") private var contextMenuActionsEnabled = true

    private let listCardBackground = Color(hex: "#161622") ?? .black
    private static let styleTagRegex = "(?is)<style[\\s\\S]*?</style>"
    private static let scriptTagRegex = "(?is)<script[\\s\\S]*?</script>"

    var body: some View {
        ZStack {
            hexColor("#0D0D14").ignoresSafeArea()

            if viewModel.isInitialLoading {
                skeletonList
                    .transition(.opacity)
            } else {
                contentList
                    .transition(.opacity)
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText)
        .refreshable {
            showingFetchingLabel = true
            await viewModel.refresh(fetchFromServer: true)
            showingFetchingLabel = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingAIFeatures = true
                } label: {
                    Image(systemName: "sparkles.rectangle.stack")
                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                }

                Button {
                    showingCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .fullScreenCover(isPresented: $showingCompose) {
            if let active = activeAccount {
                EmailComposingView(account: active)
            }
        }
        .fullScreenCover(isPresented: $showingAIFeatures) {
            InboxAIFeaturesView(inboxThreads: visibleThreads)
        }
        .navigationDestination(isPresented: $showingUniversalInbox) {
            UniversalInboxView()
        }
        .task {
            mailStore.reloadAccounts()
            if mailStore.activeAccount == nil {
                mailStore.addOrUpdateAccount(account, makeActive: true)
            }

            guard let active = activeAccount else { return }
            viewModel.configure(account: active, folder: folder)
            await viewModel.loadCachedThenRefreshIfNeeded()
        }
        .onChange(of: mailStore.activeAccount?.id) { _, _ in
            Task {
                guard let active = activeAccount else { return }
                viewModel.configure(account: active, folder: folder)
                await viewModel.loadCachedThenRefreshIfNeeded()
            }
        }
    }

    private var activeAccount: MailAccount? {
        mailStore.activeAccount ?? account
    }

    private var filteredThreadsBeforeCategory: [MailThread] {
        var base = viewModel.localThreads
        if filter == .unread {
            base = base.filter { !$0.isRead }
        }
        if !searchText.isEmpty {
            base = base.filter {
                $0.subject.localizedCaseInsensitiveContains(searchText) ||
                $0.snippet.localizedCaseInsensitiveContains(searchText) ||
                $0.participants.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
        return base
    }

    private var visibleThreads: [MailThread] {
        if selectedCategory == .all {
            return categorizedThreads.map { $0.thread }
        }
        return categorizedThreads.filter { $0.category == selectedCategory }.map { $0.thread }
    }

    private var categoryCounts: [InboxCategory: Int] {
        var counts: [InboxCategory: Int] = [.all: categorizedThreads.count]
        for category in InboxCategory.selectableCases where category != .all {
            counts[category] = categorizedThreads.filter { $0.category == category }.count
        }
        return counts
    }

    private var categorizedThreads: [(thread: MailThread, category: InboxCategory)] {
        filteredThreadsBeforeCategory.map { thread in
            (thread: thread, category: MailCategoryClassifier.category(for: thread))
        }
    }

    private var contentList: some View {
        List {
            Section {
                categoryChips
            }
            .listRowBackground(listCardBackground)

            if showingFetchingLabel {
                Section {
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text("Fetching email")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(listCardBackground)
            }

            if visibleThreads.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No messages")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Pull to refresh to fetch latest email.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(visibleThreads) { thread in
                    if let message = thread.messages.last {
                        Button {
                            selectedMessage = message
                        } label: {
                            inboxRow(thread: thread, message: message)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            swipeActionButton(for: leadingSwipeAction, thread: thread, message: message)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            swipeActionButton(for: trailingSwipeAction, thread: thread, message: message)
                        }
                        .contextMenu {
                            if contextMenuActionsEnabled {
                                Button { Task { await performThreadAction("delete", thread: thread, message: message) } } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { Task { await performThreadAction("archive", thread: thread, message: message) } } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                Button { Task { await performThreadAction("flag", thread: thread, message: message) } } label: {
                                    Label("Flag Important", systemImage: "flag.fill")
                                }
                                Button { Task { await performThreadAction("move", thread: thread, message: message) } } label: {
                                    Label("Move to Folder", systemImage: "folder")
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationDestination(item: $selectedMessage) { message in
            InboxMessageDetailView(account: activeAccount ?? account, message: message)
        }
        .alert("Mail Action", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InboxCategory.selectableCases) { category in
                    let selected = selectedCategory == category
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(category.title)
                            Text("\(categoryCounts[category] ?? 0)")
                                .foregroundStyle(selected ? .white.opacity(0.9) : .secondary)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selected ? category.tint.opacity(0.85) : Color.white.opacity(0.08), in: Capsule())
                        .foregroundStyle(selected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func inboxRow(thread: MailThread, message: MailMessage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(thread.isRead ? Color.clear : providerColor((activeAccount ?? account).providerType))
                        .frame(width: 8, height: 8)

                    Text(senderName(from: message.from))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                Text(relativeTimestamp(message.date))
                    .font(.caption2)
                    .foregroundStyle(hexColor("#8888AA"))
            }

            Text(message.subject)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(previewText(for: message))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 6)
    }

    private var skeletonList: some View {
        List {
            ForEach(0..<8, id: \.self) { _ in
                SkeletonMailRow()
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func relativeTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func senderName(from value: String) -> String {
        if let range = value.range(of: "<") {
            return String(value[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return value
    }

    private func previewText(for message: MailMessage) -> String {
        if let htmlBody = message.htmlBody,
           let htmlPreview = htmlToPreviewText(htmlBody),
           !htmlPreview.isEmpty {
            return htmlPreview
        }

        let source = normalizedPreviewText(message.body)
        guard !source.isEmpty else { return "No preview" }
        return source
    }

    private func htmlToPreviewText(_ html: String) -> String? {
        guard let data = html.data(using: .utf8) else { return nil }
        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) {
            return normalizedPreviewText(attributed.string)
        }
        return normalizedPreviewText(html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression))
    }

    private func normalizedPreviewText(_ value: String) -> String {
        var cleaned = value
            .replacingOccurrences(of: Self.styleTagRegex, with: " ", options: .regularExpression)
            .replacingOccurrences(of: Self.scriptTagRegex, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let attributed = try? AttributedString(
            markdown: cleaned,
            options: .init(interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedIfPossible)
        ) {
            let markdownStripped = String(attributed.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            cleaned = markdownStripped.isEmpty ? cleaned : markdownStripped
        }

        return cleaned
    }

    @ViewBuilder
    private func swipeActionButton(for actionID: String, thread: MailThread, message: MailMessage) -> some View {
        switch actionID {
        case "archive":
            Button {
                Task { await performThreadAction("archive", thread: thread, message: message) }
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(.blue)
        case "flag":
            Button {
                Task { await performThreadAction("flag", thread: thread, message: message) }
            } label: {
                Label("Flag", systemImage: "flag.fill")
            }
            .tint(.orange)
        case "move":
            Button {
                Task { await performThreadAction("move", thread: thread, message: message) }
            } label: {
                Label("Move", systemImage: "folder")
            }
            .tint(.indigo)
        default:
            Button(role: .destructive) {
                Task { await performThreadAction("delete", thread: thread, message: message) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func performThreadAction(_ actionID: String, thread: MailThread, message: MailMessage) async {
        switch actionID {
        case "delete":
            do {
                try await providerDelete(account: activeAccount ?? account, messageID: message.id)
                await viewModel.refresh(fetchFromServer: true)
            } catch {
                actionError = error.localizedDescription
            }
        case "archive":
            do {
                try await providerMarkReadForArchive(account: activeAccount ?? account, messageID: message.id)
                await viewModel.refresh(fetchFromServer: true)
            } catch {
                actionError = error.localizedDescription
            }
        case "flag":
            viewModel.toggleStar(messageID: message.id)
        case "move":
            viewModel.moveMessageToFolderHint(messageID: message.id)
        default:
            break
        }
    }

    private func providerDelete(account: MailAccount, messageID: String) async throws {
        switch account.providerType {
        case .gmail:
            try await GmailProvider().deleteMessage(session: providerSession(for: account), id: messageID)
        case .outlook:
            try await OutlookProvider().deleteMessage(session: providerSession(for: account), id: messageID)
        case .yahoo:
            try await YahooMailProvider().deleteMessage(session: providerSession(for: account), id: messageID)
        case .proton:
            try await ProtonMailProvider().deleteMessage(session: providerSession(for: account), id: messageID)
        case .imap, .icloud:
            try await IMAPProvider().deleteMessage(session: providerSession(for: account), id: messageID)
        }
    }

    private func providerMarkReadForArchive(account: MailAccount, messageID: String) async throws {
        switch account.providerType {
        case .gmail:
            try await GmailProvider().markRead(session: providerSession(for: account), id: messageID)
        case .outlook:
            try await OutlookProvider().markRead(session: providerSession(for: account), id: messageID)
        case .yahoo:
            try await YahooMailProvider().markRead(session: providerSession(for: account), id: messageID)
        case .proton:
            try await ProtonMailProvider().markRead(session: providerSession(for: account), id: messageID)
        case .imap, .icloud:
            try await IMAPProvider().markRead(session: providerSession(for: account), id: messageID)
        }
    }

    private func providerSession(for account: MailAccount) -> MailSession {
        MailSession(
            id: account.id,
            provider: account.providerType,
            email: account.emailAddress,
            displayName: account.displayName,
            accessTokenExpiration: account.accessTokenExpiration,
            imapHost: account.imapHost ?? "imap.mail.me.com",
            imapPort: account.imapPort ?? 993,
            smtpHost: account.smtpHost ?? "smtp.mail.me.com",
            smtpPort: account.smtpPort ?? 587
        )
    }

    private func providerColor(_ provider: MailAccount.ProviderType) -> Color {
        switch provider {
        case .gmail: return hexColor("#EA4335")
        case .outlook: return hexColor("#0078D4")
        case .yahoo: return hexColor("#6C3BD1")
        case .proton: return hexColor("#2E8B57")
        case .imap: return hexColor("#9090AE")
        case .icloud: return .blue
        }
    }

    private func hexColor(_ value: String) -> Color {
        Color(hex: value) ?? .black
    }
}

@MainActor
final class InboxScreenViewModel: ObservableObject {
    @Published var localThreads: [MailThread] = []
    @Published var isInitialLoading = true

    private let storage = MailStorageService.shared
    private var account: MailAccount?
    private var folder: MailFolder = .inbox

    func configure(account: MailAccount, folder: MailFolder) {
        self.account = account
        self.folder = folder
    }

    func loadCachedThenRefreshIfNeeded() async {
        guard let account else {
            isInitialLoading = false
            return
        }

        let key = "\(account.id)_\(folder.id)"
        let cached = storage.loadThreads(for: key)
        localThreads = cached

        if cached.isEmpty {
            isInitialLoading = true
            await refresh(fetchFromServer: true)
            isInitialLoading = false
        } else {
            isInitialLoading = false
        }
    }

    func refresh(fetchFromServer: Bool) async {
        guard let account else { return }
        if fetchFromServer {
            await MailSyncService.shared.fetchThreads(account: account, folder: folder)
        }

        let key = "\(account.id)_\(folder.id)"
        localThreads = storage.loadThreads(for: key)
    }

    func toggleStar(messageID: String) {
        guard let account else { return }
        for threadIndex in localThreads.indices {
            for messageIndex in localThreads[threadIndex].messages.indices where localThreads[threadIndex].messages[messageIndex].id == messageID {
                localThreads[threadIndex].messages[messageIndex].isStarred.toggle()
            }
        }
        storage.saveThreads(localThreads, for: "\(account.id)_\(folder.id)")
    }

    func moveMessageToFolderHint(messageID: String) {
        let key = "mail.move.map"
        var map = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        map[messageID] = "Later"
        UserDefaults.standard.set(map, forKey: key)
    }

}

private struct SkeletonMailRow: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.13))
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.11))
                    .frame(height: 11)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.09))
                    .frame(height: 10)
                    .frame(maxWidth: 180)
            }
        }
        .padding(12)
        .background(Color(hex: "#161622") ?? Color.black, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.clear, .white.opacity(0.25), .clear], startPoint: .leading, endPoint: .trailing)
                    )
                    .offset(x: phase * geo.size.width)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                phase = 1.3
            }
        }
    }
}

private struct InboxMessageDetailView: View {
    let account: MailAccount
    let message: MailMessage

    @Environment(\.dismiss) private var dismiss

    @State private var showReply = false
    @State private var isSummarizing = false
    @State private var summary: String?
    @State private var actionError: String?

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if isSummarizing {
                        summarizingIndicator
                    }

                    if let summary, !summary.isEmpty {
                        summarySection(summary: summary)
                    }

                    messageContent(geo: geo)

                    if let actionError {
                        Text(actionError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(16)
            }
            .background(Color(hex: "#0D0D14") ?? .black)
            .navigationTitle("Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                messageToolbar
            }
            .fullScreenCover(isPresented: $showReply) {
                EmailComposingView(account: account, replyTo: message)
            }
        }
    }

    private var summarizingIndicator: some View {
        HStack {
            ProgressView()
                .tint(.purple)
            Text("Generating Intelligent Summary...")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private func summarySection(summary: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("AI Summary", systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Spacer()
                Button {
                    UIPasteboard.general.string = summary
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue.opacity(0.8))
            }

            MarkdownSummaryText(text: summary)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LinearGradient(colors: [Color.blue.opacity(0.45), Color.cyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func messageContent(geo: GeometryProxy) -> some View {
        if let htmlBody = message.htmlBody, !htmlBody.isEmpty {
            MessageWebView(html: htmlBody)
                .frame(minHeight: max(geo.size.height * 0.78, 420))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            Text(message.body)
                .font(.body)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: max(geo.size.height * 0.72, 380), alignment: .topLeading)
        }
    }

    private var messageToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    summarize()
                } label: {
                    Label("Summarize", systemImage: "text.justify.leading")
                }

                Button {
                    showReply = true
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }

                Button {
                    Task { await archiveMessage() }
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }

                Button(role: .destructive) {
                    Task { await deleteMessage() }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.subject)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(message.from)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func summarize() {
        guard !isSummarizing else { return }
        isSummarizing = true
        summary = nil
        actionError = nil

        Task {
            do {
                let input = message.body.isEmpty ? message.subject : message.body
                let response = try await AIService.shared.processText(
                    prompt: """
                    Write an ultra-short markdown summary for this email in at most 4 bullets.
                    Include only what matters now and any clear next step.
                    DO NOT SAY NOTHING ELSE, ONLY THE SUMMARY

                    Email:
                    \(input)
                    """,
                    systemPrompt: "You are a concise executive email summarizer. Prefer short bullets and factual statements only."
                )
                await MainActor.run {
                    summary = response
                    isSummarizing = false
                }
            } catch {
                await MainActor.run {
                    actionError = error.localizedDescription
                    isSummarizing = false
                }
            }
        }
    }

    private func deleteMessage() async {
        do {
            try await providerDelete(account: account, messageID: message.id)
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func archiveMessage() async {
        do {
            try await providerMarkReadForArchive(account: account, messageID: message.id)
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func providerDelete(account: MailAccount, messageID: String) async throws {
        switch account.providerType {
        case .gmail:
            try await GmailProvider().deleteMessage(session: providerSession(), id: messageID)
        case .outlook:
            try await OutlookProvider().deleteMessage(session: providerSession(), id: messageID)
        case .yahoo:
            try await YahooMailProvider().deleteMessage(session: providerSession(), id: messageID)
        case .proton:
            try await ProtonMailProvider().deleteMessage(session: providerSession(), id: messageID)
        case .imap, .icloud:
            try await IMAPProvider().deleteMessage(session: providerSession(), id: messageID)
        }
    }

    private func providerMarkReadForArchive(account: MailAccount, messageID: String) async throws {
        switch account.providerType {
        case .gmail:
            try await GmailProvider().markRead(session: providerSession(), id: messageID)
        case .outlook:
            try await OutlookProvider().markRead(session: providerSession(), id: messageID)
        case .yahoo:
            try await YahooMailProvider().markRead(session: providerSession(), id: messageID)
        case .proton:
            try await ProtonMailProvider().markRead(session: providerSession(), id: messageID)
        case .imap, .icloud:
            try await IMAPProvider().markRead(session: providerSession(), id: messageID)
        }
    }

    private func providerSession() -> MailSession {
        MailSession(
            id: account.id,
            provider: account.providerType,
            email: account.emailAddress,
            displayName: account.displayName,
            accessTokenExpiration: account.accessTokenExpiration,
            imapHost: account.imapHost ?? "imap.mail.me.com",
            imapPort: account.imapPort ?? 993,
            smtpHost: account.smtpHost ?? "smtp.mail.me.com",
            smtpPort: account.smtpPort ?? 587
        )
    }
}

private struct MarkdownSummaryText: View {
    let text: String

    var body: some View {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedIfPossible)) {
            Text(attributed)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MessageWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let css = """
        <style>
        body { background: #0D0D14; color: #E0E0F0; font-family: -apple-system; font-size: 15px; margin: 0; padding: 0; }
        a { color: #88A8FF; }
        </style>
        """
        let document = "<html><head>\(css)</head><body>\(html)</body></html>"
        uiView.loadHTMLString(document, baseURL: nil)
    }
}
