import SwiftUI
import WebKit

struct InboxView: View {
    let account: MailAccount
    let folder: MailFolder
    var filter: InboxFilter = .all

    enum InboxFilter {
        case all, unread
    }

    @StateObject private var syncService = MailSyncService.shared
    @StateObject private var storage = MailStorageService.shared
    @StateObject private var mailStore = MailStore.shared
    @StateObject private var viewModel = InboxScreenViewModel()

    @State private var searchText = ""
    @State private var showingCompose = false
    @State private var showingAddAccount = false
    @State private var showingFetchingLabel = false
    @State private var showPriorityAll = false
    @State private var showCatchUpAll = false
    private let cardPreviewCount = 4

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
        .navigationTitle(mailStore.activeAccount?.emailAddress ?? account.emailAddress)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .searchable(text: $searchText)
        .refreshable {
            showingFetchingLabel = true
            await viewModel.refresh()
            showingFetchingLabel = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingAddAccount = true
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                }

                Button {
                    showingCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingCompose) {
            if let activeAccount {
                EmailComposingView(account: activeAccount)
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddMailAccountView { selected in
                mailStore.setActiveAccount(selected.id)
                Task {
                    await viewModel.refresh()
                }
            }
        }
        .sheet(isPresented: $showPriorityAll) {
            NavigationStack {
                ThreadListSheet(title: "Priority", threads: priorityThreads)
            }
        }
        .sheet(isPresented: $showCatchUpAll) {
            NavigationStack {
                ThreadListSheet(title: "Catch Up", threads: catchUpThreads)
            }
        }
        .task {
            mailStore.reloadAccounts()
            if mailStore.activeAccount == nil {
                mailStore.addOrUpdateAccount(account, makeActive: true)
            }

            if let active = activeAccount {
                viewModel.configure(account: active, folder: folder)
                let key = folderKey(for: active)
                _ = storage.loadThreads(for: key)
                viewModel.localThreads = storage.threads
                await viewModel.initialLoad()
                _ = storage.loadThreads(for: key)
                viewModel.localThreads = storage.threads
            }
        }
        .onChange(of: mailStore.activeAccount?.id) { _ in
            Task {
                guard let active = activeAccount else { return }
                viewModel.configure(account: active, folder: folder)
                _ = storage.loadThreads(for: folderKey(for: active))
                viewModel.localThreads = storage.threads
                await viewModel.refresh()
                _ = storage.loadThreads(for: folderKey(for: active))
                viewModel.localThreads = storage.threads
            }
        }
    }

    private var activeAccount: MailAccount? {
        mailStore.activeAccount ?? account
    }

    private var visibleThreads: [MailThread] {
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

    private var priorityThreads: [MailThread] {
        Array(viewModel.localThreads.filter { !$0.isRead }.prefix(cardPreviewCount))
    }

    private var catchUpThreads: [MailThread] {
        Array(viewModel.localThreads.prefix(cardPreviewCount))
    }

    private var contentList: some View {
        List {
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
                .listRowBackground(hexColor("#161622"))
            }

            sectionCards

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
                .listRowBackground(.clear)
            } else {
                ForEach(visibleThreads) { thread in
                    if let message = thread.messages.last {
                        NavigationLink {
                            InboxMessageDetailView(account: activeAccount ?? account, message: message)
                        } label: {
                            inboxRow(thread: thread, message: message)
                        }
                        .listRowBackground(.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var sectionCards: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    compactCard(title: "Priority", threads: priorityThreads, seeAll: { showPriorityAll = true })
                    compactCard(title: "Catch Up", threads: catchUpThreads, seeAll: { showCatchUpAll = true })
                }
                .padding(.vertical, 2)
            }
        }
        .listRowBackground(.clear)
        .listRowSeparator(.hidden)
    }

    private func compactCard(title: String, threads: [MailThread], seeAll: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button("See all", action: seeAll)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hexColor("#9EA4FF"))
            }

            ForEach(Array(threads.prefix(cardPreviewCount))) { item in
                Text(item.subject)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if threads.isEmpty {
                Text("No items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(width: 160, height: 90, alignment: .topLeading)
        .background(hexColor("#1E1E2E"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    private func inboxRow(thread: MailThread, message: MailMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(thread.isRead ? Color.clear : providerColor((activeAccount ?? account).providerType))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(senderName(from: message.from))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Text(relativeTimestamp(message.date))
                        .font(.caption2)
                        .foregroundStyle(hexColor("#8888AA"))
                }

                Text(message.subject)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(message.body.isEmpty ? "No preview" : message.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(hexColor("#161622"), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.20), radius: 5, x: 0, y: 2)
    }

    private var skeletonList: some View {
        List {
            ForEach(0..<8, id: \.self) { _ in
                SkeletonMailRow()
                    .listRowBackground(.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func folderKey(for account: MailAccount) -> String { "\(account.id)_\(folder.id)" }

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

    private var account: MailAccount?
    private var folder: MailFolder = .inbox

    func configure(account: MailAccount, folder: MailFolder) {
        self.account = account
        self.folder = folder
    }

    func initialLoad() async {
        guard let account else {
            isInitialLoading = false
            return
        }
        isInitialLoading = true
        await MailSyncService.shared.fetchThreads(account: account, folder: folder)
        isInitialLoading = false
    }

    func refresh() async {
        guard let account else { return }
        await MailSyncService.shared.fetchThreads(account: account, folder: folder)
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

private struct ThreadListSheet: View {
    let title: String
    let threads: [MailThread]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(threads) { thread in
            VStack(alignment: .leading, spacing: 5) {
                Text(thread.subject)
                    .font(.headline)
                Text(thread.participants.first ?? "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(thread.snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct InboxMessageDetailView: View {
    let account: MailAccount
    let message: MailMessage

    @State private var showReply = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(message.subject)
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text(message.from)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let htmlBody = message.htmlBody, !htmlBody.isEmpty {
                    MessageWebView(html: htmlBody)
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(message.body)
                        .font(.body)
                        .foregroundStyle(.white)
                }

                Button {
                    showReply = true
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#23233A") ?? .black, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
        }
        .background(Color(hex: "#0D0D14") ?? .black)
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showReply) {
            ReplyComposerView(account: account, originalMessage: message)
        }
    }
}

private struct ReplyComposerView: View {
    let account: MailAccount
    let originalMessage: MailMessage

    @State private var responseText = ""
    @State private var markdownPreview = AttributedString("")
    @State private var isSending = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Response")
                        .font(.caption.smallCaps().weight(.semibold))
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $responseText)
                            .frame(minHeight: 140)
                            .padding(6)
                            .background(Color(hex: "#1A1A26") ?? .black, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                            .onChange(of: responseText) { value in
                                markdownPreview = (try? AttributedString(markdown: value)) ?? AttributedString(value)
                            }

                        if responseText.isEmpty {
                            Text("Write your reply…")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .allowsHitTesting(false)
                        }
                    }

                    Text(markdownPreview)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Message")
                        .font(.caption.smallCaps().weight(.semibold))
                        .foregroundStyle(.secondary)

                    MessageWebView(html: sanitizedOriginalHTML)
                        .frame(minHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await sendReply() }
                } label: {
                    HStack {
                        if isSending { ProgressView().tint(.white) }
                        Text("Send Reply")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#2A3A6A") ?? .blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .disabled(isSending || responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
        }
        .background(Color(hex: "#0D0D14") ?? .black)
        .navigationTitle("Reply")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sanitizedOriginalHTML: String {
        if let html = originalMessage.htmlBody, !html.isEmpty {
            let withoutScripts = html.replacingOccurrences(of: "<script[\\s\\S]*?</script>", with: "", options: .regularExpression)
            let withoutHandlers = withoutScripts
                .replacingOccurrences(of: "\\son[a-zA-Z]+\\s*=\\s*\"[^\"]*\"", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\son[a-zA-Z]+\\s*=\\s*'[^']*'", with: "", options: .regularExpression)
            return withoutHandlers.replacingOccurrences(of: "(href|src)\\s*=\\s*['\"]javascript:[^'\"]*['\"]", with: "", options: .regularExpression)
        }
        return "<pre>\(originalMessage.body)</pre>"
    }

    private func sendReply() async {
        isSending = true
        defer { isSending = false }

        let draft = MailDraft(
            from: account.emailAddress,
            to: [extractEmail(from: originalMessage.from)],
            subject: "Re: \(originalMessage.subject)",
            bodyText: responseText,
            bodyHTML: nil
        )

        do {
            let session = MailSession(
                id: account.id,
                provider: account.providerType,
                email: account.emailAddress,
                displayName: account.displayName,
                accessToken: account.accessToken,
                refreshToken: account.refreshToken,
                imapHost: nil,
                imapPort: nil,
                smtpHost: nil,
                smtpPort: nil
            )

            switch account.providerType {
            case .gmail:
                try await GmailProvider().sendMessage(session: session, draft: draft)
            case .outlook:
                try await OutlookProvider().sendMessage(session: session, draft: draft)
            case .yahoo:
                try await YahooMailProvider().sendMessage(session: session, draft: draft)
            case .proton:
                try await ProtonMailProvider().sendMessage(session: session, draft: draft)
            case .imap, .icloud:
                try await IMAPProvider().sendMessage(
                    session: MailSession(
                        id: account.id,
                        provider: .imap,
                        email: account.emailAddress,
                        displayName: account.displayName,
                        accessToken: nil,
                        refreshToken: nil,
                        imapHost: account.imapHost ?? "imap.mail.me.com",
                        imapPort: account.imapPort ?? 993,
                        smtpHost: account.smtpHost ?? "smtp.mail.me.com",
                        smtpPort: account.smtpPort ?? 587
                    ),
                    draft: draft
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func extractEmail(from source: String) -> String {
        if let start = source.lastIndex(of: "<"), let end = source.lastIndex(of: ">"), start < end {
            let inner = source[source.index(after: start)..<end]
            let candidate = String(inner)
            if candidate.contains("@") {
                return candidate
            }
        }
        return source
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
