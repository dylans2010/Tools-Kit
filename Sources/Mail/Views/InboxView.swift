import SwiftUI
import WebKit
import UIKit

struct InboxView: View {
    let account: MailAccount
    let folder: MailFolder
    @State private var filter: InboxFilter = .all

    enum InboxFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case unread = "Unread"
        case attention = "Attention"

        var id: String { self.rawValue }
    }

    @StateObject private var storage = MailStorageService.shared
    @StateObject private var mailStore = MailStore.shared
    @StateObject private var viewModel = InboxScreenViewModel()

    @State private var searchText = ""
    @State private var showingCompose = false
    @State private var showingAIFeatures = false
    @State private var showingAIDashboard = false
    @State private var showingUniversalInbox = false
    @State private var showingSearch = false
    @State private var showingFetchingLabel = false
    @State private var selectedMessage: MailMessage?
    @State private var actionError: String?

    @AppStorage("mail.settings.swipe.leading") private var leadingSwipeAction = "flag"
    @AppStorage("mail.settings.swipe.trailing") private var trailingSwipeAction = "delete"
    @AppStorage("mail.settings.contextMenu.enabled") private var contextMenuActionsEnabled = true

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if viewModel.isInitialLoading {
                    skeletonList
                        .transition(.opacity)
                        .padding(.top, 10)
                } else {
                    listContent
                        .transition(.opacity)
                }
            }

            VStack {
                Spacer()
                bottomTabBar
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingComposeButton
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationBarHidden(true)
        .searchable(text: $searchText, prompt: "Search emails")
        .fullScreenCover(isPresented: $showingCompose) {
            if let active = activeAccount {
                EmailComposingView(account: active)
            }
        }
        .sheet(isPresented: $showingAIFeatures) {
            InboxAIFeaturesView(inboxThreads: visibleThreads, account: activeAccount)
        }
        .sheet(isPresented: $showingAIDashboard) {
            NavigationStack {
                AIInboxDashboard()
            }
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

        switch filter {
        case .all:
            break
        case .unread:
            base = base.filter { !$0.isRead }
        case .attention:
            // Filter for priority emails (score > 0.7) or specific intents
            base = base.filter { ($0.priorityScore ?? 0) > 0.7 || $0.intent == "meeting_request" || $0.intent == "task_assignment" }
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

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    showingUniversalInbox = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text(filter.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())

                Spacer()

                Button {
                    withAnimation {
                        showingSearch.toggle()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(showingSearch ? .blue : .primary)
                }

                Menu {
                    Button {
                        showingAIFeatures = true
                    } label: {
                        Label("AI Features", systemImage: "sparkles")
                    }

                    Button {
                        showingAIDashboard = true
                    } label: {
                        Label("AI Dashboard", systemImage: "gauge.with.dots.needle.bottom.100percent")
                    }

                    NavigationLink(destination: PriorityQueueView()) {
                        Label("Priority Queue", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    NavigationLink(destination: WorkflowExecutionMonitor()) {
                        Label("Workflow Monitor", systemImage: "cpu")
                    }
                } label: {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }

            if showingSearch {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search emails...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if showingFetchingLabel {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Fetching email...")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                if visibleThreads.isEmpty {
                    emptyStateView
                } else {
                    let today = visibleThreads.filter { Calendar.current.isDateInToday($0.lastMessageDate) }
                    let yesterday = visibleThreads.filter { Calendar.current.isDateInYesterday($0.lastMessageDate) }
                    let week = visibleThreads.filter {
                        let date = $0.lastMessageDate
                        let calendar = Calendar.current
                        return !calendar.isDateInToday(date) && !calendar.isDateInYesterday(date) && calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
                    }
                    let older = visibleThreads.filter {
                        let date = $0.lastMessageDate
                        let calendar = Calendar.current
                        return !calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) && date < Date()
                    }

                    if !today.isEmpty {
                        sectionView(title: "Today", threads: today)
                    }
                    if !yesterday.isEmpty {
                        sectionView(title: "Yesterday", threads: yesterday)
                    }
                    if !week.isEmpty {
                        sectionView(title: "This Week", threads: week)
                    }
                    if !older.isEmpty {
                        sectionView(title: "Older", threads: older)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
        .refreshable {
            showingFetchingLabel = true
            await viewModel.refresh(fetchFromServer: true)
            showingFetchingLabel = false
        }
        .navigationDestination(item: $selectedMessage) { message in
            InboxMessageDetailView(account: activeAccount ?? account, message: message)
        }
        .alert("Mail Action", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: filter == .attention ? "sparkles" : "tray")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(filter == .attention ? "Inbox Zero Reached" : "No messages")
                .font(.headline)
            Text(filter == .attention ? "You've cleared everything that needs immediate attention." : "Pull to refresh to fetch latest email.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func sectionView(title: String, threads: [MailThread]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(threads) { thread in
                    if let message = thread.messages.last {
                        emailRow(thread: thread, message: message)
                        if thread.id != threads.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private func emailRow(thread: MailThread, message: MailMessage) -> some View {
        Button(action: {
            selectedMessage = message
        }) {
            HStack(spacing: 12) {
                avatarView(message: message)
                VStack(alignment: .leading, spacing: 4) {
                    Text(senderName(from: message.from))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(message.subject)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(relativeTimestamp(message.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
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
                Button {
                    Task {
                        _ = try? await ExecutionBridge.shared.convertThreadToCalendarEvent(thread: thread)
                    }
                } label: {
                    Label("Create Calendar Event", systemImage: "calendar.badge.plus")
                }
            }
        }
    }

    private func avatarView(message: MailMessage) -> some View {
        ZStack {
            Circle()
                .fill(providerColor((activeAccount ?? account).providerType).opacity(0.2))
                .frame(width: 44, height: 44)

            Text(senderInitials(from: message.from))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(providerColor((activeAccount ?? account).providerType))
        }
    }

    private var bottomTabBar: some View {
        HStack {
            tabItem(icon: "envelope.fill", label: "Inbox", isActive: filter == .all)
                .onTapGesture { filter = .all }
            tabItem(icon: "star.fill", label: "Important", isActive: filter == .attention)
                .onTapGesture { filter = .attention }
            tabItem(icon: "square.grid.2x2.fill", label: "Library", isActive: false)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
        .shadow(radius: 6)
        .padding(.horizontal, 40)
        .padding(.bottom, 10)
    }

    private func tabItem(icon: String, label: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(isActive ? .accentColor : .secondary)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var floatingComposeButton: some View {
        Button(action: {
            showingCompose = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .frame(width: 60, height: 60)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
        .padding()
        .shadow(radius: 4)
    }


    private func senderInitials(from value: String) -> String {
        let name = senderName(from: value)
        let components = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1).uppercased()
            let last = components[1].prefix(1).uppercased()
            return first + last
        } else if let first = components.first?.prefix(1).uppercased() {
            return first
        }
        return "?"
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
            return sanitizePreviewText(rendered)
        }

        let source = sanitizePreviewText(message.body)
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

    private func sanitizePreviewText(_ input: String) -> String {
        let noCodeBlocks = input.replacingOccurrences(of: "<style[\\s\\S]*?</style>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<script[\\s\\S]*?</script>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\{[^\\}]*:[^\\}]*\\}", with: " ", options: .regularExpression)
        let decoded = noCodeBlocks
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return decoded
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
        case .gmail: return Color(hex: "#EA4335")
        case .outlook: return Color(hex: "#0078D4")
        case .yahoo: return Color(hex: "#6C3BD1")
        case .proton: return Color(hex: "#2E8B57")
        case .imap: return Color(hex: "#9090AE")
        case .icloud: return .blue
        }
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
        var threads = storage.loadThreads(for: key)

        // Enrich threads with AI classification if missing
        for i in threads.indices where threads[i].intent == nil {
            threads[i].intent = try? await MailAIService.shared.classifyIntent(for: threads[i])
            threads[i].priorityScore = Double.random(in: 0...1) // Simulated
        }

        localThreads = threads
        storage.saveThreads(threads, for: key)
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
        .background(Color(hex: "#161622"), in: RoundedRectangle(cornerRadius: 12))
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

struct InboxMessageDetailView: View {
    let account: MailAccount
    let message: MailMessage

    @Environment(\.dismiss) private var dismiss

    @State private var showReply = false
    @State private var isSummarizing = false
    @State private var summary: String?
    @State private var actionError: String?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        detailHeader

                        subjectAndToCards

                        if isSummarizing {
                            summarizingIndicator
                        }

                        if let summary, !summary.isEmpty {
                            summarySection(summary: summary)
                        }

                        bodyContainer(geo: geo)

                        if !message.attachments.isEmpty {
                            attachmentsSection
                        }

                        if let actionError {
                            Text(actionError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(16)
                }

                VStack {
                    Spacer()
                    bottomActions
                }
            }
            .navigationTitle("Message")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showReply) {
                EmailComposingView(account: account, replyTo: message)
            }
        }
    }

    private var detailHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(Text(message.from.prefix(1).uppercased()).bold().foregroundColor(.accentColor))

            VStack(alignment: .leading, spacing: 2) {
                Text(message.from)
                    .font(.headline)
                Text("To: Me")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(message.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }

    private var subjectAndToCards: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Subject")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(message.subject)
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)

            VStack(alignment: .leading, spacing: 4) {
                Text("To")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(message.to.joined(separator: ", "))
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }

    private func bodyContainer(geo: GeometryProxy) -> some View {
        VStack {
            messageContent(geo: geo)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachments")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(message.attachments) { attachment in
                        VStack {
                            Image(systemName: "doc.fill")
                                .font(.title)
                            Text(attachment.fileName)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 16) {
            Button {
                showReply = true
            } label: {
                Text("Reply")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(16)
            }

            Button {
                summarize()
            } label: {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Button {
                Task { await archiveMessage() }
            } label: {
                Image(systemName: "archivebox")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Button(role: .destructive) {
                Task { await deleteMessage() }
            } label: {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
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
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))
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
