import SwiftUI
#if canImport(WebKit)
import WebKit
#endif
#if canImport(UIKit)
import UIKit
#endif

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

    @State private var selectedTab = 0

    @AppStorage("mail.settings.swipe.leading") private var leadingSwipeAction = "flag"
    @AppStorage("mail.settings.swipe.trailing") private var trailingSwipeAction = "delete"
    @AppStorage("mail.settings.contextMenu.enabled") private var contextMenuActionsEnabled = true

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                inboxContent
                    .navigationTitle(folder.name)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showingUniversalInbox = true
                            } label: {
                                Image(systemName: "line.3.horizontal")
                            }
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 16) {
                                Button {
                                    withAnimation { showingSearch.toggle() }
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                }

                                Menu {
                                    Button { showingAIFeatures = true } label: { Label("AI Features", systemImage: "sparkles") }
                                    Button { showingAIDashboard = true } label: { Label("AI Dashboard", systemImage: "gauge") }
                                    NavigationLink(destination: PriorityQueueView()) { Label("Priority Queue", systemImage: "line.3.horizontal.decrease.circle") }
                                    NavigationLink(destination: WorkflowExecutionMonitor()) { Label("Workflow Monitor", systemImage: "cpu") }
                                } label: {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                                }
                            }
                        }
                    }
            }
            .tabItem {
                Label("Inbox", systemImage: "envelope.fill")
            }
            .tag(0)

            NavigationStack {
                inboxContent
                    .onAppear { filter = .attention }
                    .onDisappear { filter = .all }
                    .navigationTitle("Important")
            }
            .tabItem {
                Label("Important", systemImage: "star.fill")
            }
            .tag(1)

            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "bell.fill")
                }
            .tag(2)
        }
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

    private var inboxContent: some View {
        ZStack(alignment: .bottomTrailing) {
            listContent

            floatingComposeButton
        }
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if showingSearch {
                    searchBar
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if showingFetchingLabel {
                    fetchingIndicator
                        .padding(.horizontal, 16)
                }

                if visibleThreads.isEmpty {
                    emptyStateView
                        .padding(.top, 40)
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

                    VStack(spacing: 24) {
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
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 100)
        }
        .refreshable {
            showingFetchingLabel = true
            await viewModel.refresh(fetchFromServer: true)
            showingFetchingLabel = false
        }
        .navigationDestination(item: $selectedMessage) { message in
            InboxDetailView(account: activeAccount ?? account, message: message)
        }
    }

    private var searchBar: some View {
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
    }

    private var fetchingIndicator: some View {
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
                            Divider().padding(.leading, 64)
                        }
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func emailRow(thread: MailThread, message: MailMessage) -> some View {
        Button(action: {
            selectedMessage = message
        }) {
            HStack(spacing: 12) {
                avatarView(message: message)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(senderName(from: message.from))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(relativeTimestamp(message.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(message.subject)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(message.body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
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
                .fill(providerColor((activeAccount ?? account).providerType).opacity(0.1))
                .frame(width: 44, height: 44)

            Text(senderInitials(from: message.from))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(providerColor((activeAccount ?? account).providerType))
        }
    }

    private var floatingComposeButton: some View {
        Button(action: {
            showingCompose = true
        }) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 24, weight: .bold))
                .frame(width: 60, height: 60)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
        .padding(20)
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

        for i in threads.indices where threads[i].intent == nil {
            threads[i].intent = try? await MailAIService.shared.classifyIntent(for: threads[i])
            threads[i].priorityScore = Double.random(in: 0...1)
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
}
