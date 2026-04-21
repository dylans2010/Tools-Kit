import SwiftUI
import WebKit

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
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingUniversalInbox = true
                } label: {
                    Image(systemName: "tray.full")
                }
            }

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
            InboxAIFeaturesView()
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
           let rendered = MailContentRenderer.render(htmlBody: htmlBody, plainBody: message.body).plainBody,
           !rendered.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return rendered
        }

        let source = message.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return "No preview" }

        if let attributed = try? AttributedString(
            markdown: source,
            options: .init(interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedIfPossible)
        ) {
            let cleaned = String(attributed.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? source : cleaned
        }
        return source
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

                    if let summary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("AI Summary", systemImage: "sparkles")
                                    .font(.caption.bold())
                                    .foregroundStyle(.purple)
                                Spacer()
                            }

                            Text(summary)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .background(
                            LinearGradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                        )
                    }

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
            .fullScreenCover(isPresented: $showReply) {
                EmailComposingView(account: account, replyTo: message)
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
                let response = try await AIService.shared.summarize(text: input)
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
