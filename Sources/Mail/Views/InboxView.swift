import SwiftUI

struct InboxView: View {
    let account: MailAccount
    let folder: MailFolder
    var filter: InboxFilter = .all

    enum InboxFilter {
        case all, unread
    }

    @StateObject private var syncService = MailSyncService.shared
    @StateObject private var storage = MailStorageService.shared
    @State private var searchText = ""
    @State private var showingCompose = false
    @State private var catchUpSummary: String?
    @State private var isSummarizing = false

    var body: some View {
        List {
            syncStatusSection
            lastSyncedSection
            catchUpSection
            aiSummarySection
            threadListSection
        }
        .navigationTitle(filter == .unread ? "Catch Up" : folder.name)
        .searchable(text: $searchText)
        .refreshable {
            await syncService.fetchThreads(account: account, folder: folder)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCompose = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingCompose) {
            EmailComposingView(account: account)
        }
        .task {
            _ = storage.loadThreads(for: folderKey)
            await syncService.fetchThreads(account: account, folder: folder)
        }
    }

    @ViewBuilder
    private var syncStatusSection: some View {
        if syncService.isSyncing {
            Section {
                HStack(spacing: 10) {
                    ProgressView().tint(.blue)
                    Text("Fetching mail…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.blue.opacity(0.08))
            }
        }
    }

    @ViewBuilder
    private var lastSyncedSection: some View {
        if let syncDate = syncService.lastSyncDate {
            Section {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Last synced \(syncDate, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var catchUpSection: some View {
        if filter == .unread && catchUpSummary == nil && !storage.threads.isEmpty {
            Section {
                Button(action: runCatchUp) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(isSummarizing ? "AI is catching up..." : "Catch Up with AI")
                            .fontWeight(.bold)
                        Spacer()
                        if isSummarizing {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }
        }
    }

    @ViewBuilder
    private var aiSummarySection: some View {
        if let summary = catchUpSummary {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AI Catch Up")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }

                    Text(summary)
                        .font(.subheadline)
                        .lineSpacing(4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var threadListSection: some View {
        ForEach(filteredThreads) { thread in
            threadRow(thread)
        }
    }

    @ViewBuilder
    private func threadRow(_ thread: MailThread) -> some View {
        if let message = thread.messages.last {
            NavigationLink(
                destination: MailThreadView(
                    viewModel: MailViewModel(),
                    email: EmailMessage(
                        uid: Int(message.id) ?? 0,
                        subject: message.subject,
                        sender: message.from,
                        date: message.date,
                        preview: String(message.body.prefix(100)),
                        isRead: message.isRead,
                        body: message.body,
                        htmlBody: message.htmlBody
                    )
                )
            ) {
                MailThreadRow(thread: thread)
            }
            .swipeActions(edge: .leading) {
                Button {
                    toggleStar(thread)
                } label: {
                    Label("Star", systemImage: thread.messages.first?.isStarred == true ? "star.slash" : "star")
                }
                .tint(.yellow)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    deleteThread(thread)
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    toggleRead(thread)
                } label: {
                    Label(thread.isRead ? "Unread" : "Read", systemImage: thread.isRead ? "envelope.badge" : "envelope.open")
                }
                .tint(.blue)
            }
            .onAppear {
                if thread.id == filteredThreads.last?.id {
                    Task { await syncService.fetchNextPage() }
                }
            }
        }
    }

    private var filteredThreads: [MailThread] {
        var result = storage.threads
        if filter == .unread {
            result = storage.threads.filter { !$0.isRead }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.subject.localizedCaseInsensitiveContains(searchText) || $0.snippet.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private var folderKey: String { "\(account.id)_\(folder.id)" }

    private func toggleRead(_ thread: MailThread) {
        guard let idx = storage.threads.firstIndex(where: { $0.id == thread.id }) else { return }
        let targetRead = !thread.isRead
        var updated = storage.threads
        for msgIdx in updated[idx].messages.indices {
            updated[idx].messages[msgIdx].isRead = targetRead
        }
        MailStorageService.shared.saveThreads(updated, for: folderKey)
    }

    private func toggleStar(_ thread: MailThread) {
        guard let idx = storage.threads.firstIndex(where: { $0.id == thread.id }) else { return }
        var updated = storage.threads
        let currentlyStarred = updated[idx].messages.first?.isStarred ?? false
        for msgIdx in updated[idx].messages.indices {
            updated[idx].messages[msgIdx].isStarred = !currentlyStarred
        }
        MailStorageService.shared.saveThreads(updated, for: folderKey)
    }

    private func deleteThread(_ thread: MailThread) {
        let remaining = storage.threads.filter { $0.id != thread.id }
        MailStorageService.shared.saveThreads(remaining, for: folderKey)
    }

    private func runCatchUp() {
        isSummarizing = true
        Task {
            do {
                let summary = try await MailAIService.shared.catchUp(unreadThreads: storage.threads.filter { !$0.isRead })
                DispatchQueue.main.async {
                    self.catchUpSummary = summary
                    self.isSummarizing = false
                }
            } catch {
                isSummarizing = false
            }
        }
    }
}

struct MailThreadRow: View {
    let thread: MailThread

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(thread.participants.first ?? "Unknown")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(thread.lastMessageDate, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                if !thread.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
                Text(thread.subject)
                    .font(.subheadline)
                    .fontWeight(thread.isRead ? .regular : .semibold)
                    .lineLimit(1)
            }

            Text(thread.snippet)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .lineSpacing(2)
        }
        .padding(.vertical, 8)
    }
}
