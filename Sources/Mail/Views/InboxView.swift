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
    @State private var prioritySummary: String?
    @State private var isPrioritizing = false
    @State private var catchUpSummary: String?
    @State private var isSummarizing = false

    var body: some View {
        List {
            syncStatusSection
            syncErrorSection
            lastSyncedSection
            prioritySection
            aiSummarySection
            threadListSection
        }
        .navigationTitle(filter == .unread ? "Catch Up" : folder.name)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .searchable(text: $searchText)
        .refreshable {
            await syncService.fetchThreads(account: account, folder: folder)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toolbarAction) {
                    if filter == .unread {
                        Label(isSummarizing ? "Working" : "Catch Up", systemImage: isSummarizing ? "hourglass" : "sparkles")
                    } else {
                        Image(systemName: "square.and.pencil")
                    }
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
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.blue.opacity(0.08))
            }
        }
    }

    @ViewBuilder
    private var syncErrorSection: some View {
        if let error = syncService.lastError, !error.isEmpty {
            Section {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.vertical, 4)
                    .listRowBackground(Color.red.opacity(0.08))
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
    private var prioritySection: some View {
        let unreadThreads = storage.threads.filter { !$0.isRead }

        if !unreadThreads.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Priority Brief")
                                .font(.headline)
                            Text("Focus on the unread emails that matter most first.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if isPrioritizing {
                            ProgressView()
                                .tint(.blue)
                        }
                    }

                    if let prioritySummary {
                        Text(prioritySummary)
                            .font(.subheadline)
                            .lineSpacing(4)
                    } else {
                        Button(action: runPriorityBrief) {
                            Label(isPrioritizing ? "Analyzing unread mail..." : "Analyze unread mail", systemImage: "sparkles")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 10)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isPrioritizing)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var aiSummarySection: some View {
        if let summary = catchUpSummary {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                        Text("Catch Up Summary")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }

                    Text(summary)
                        .font(.subheadline)
                        .lineSpacing(4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var threadListSection: some View {
        if filteredThreads.isEmpty {
            Section {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No messages yet" : "No matching messages")
                        .font(.headline)
                    Text(searchText.isEmpty ? "Pull to refresh to fetch your latest iCloud emails." : "Try a different sender or subject search.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            }
        } else {
            ForEach(filteredThreads) { thread in
                threadRow(thread)
            }
        }
    }

    @ViewBuilder
    private func threadRow(_ thread: MailThread) -> some View {
        if let message = thread.messages.last {
            NavigationLink(
                destination: MailThreadView(
                    viewModel: MailViewModel(),
                    email: EmailMessage(
                        uid: Int(message.id) ?? fallbackUID(from: message.id),
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
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .listRowBackground(Color.clear)
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
                await MainActor.run {
                    self.catchUpSummary = summary
                    self.isSummarizing = false
                }
            } catch {
                await MainActor.run {
                    self.isSummarizing = false
                }
            }
        }
    }

    private func runPriorityBrief() {
        isPrioritizing = true
        Task {
            do {
                let summary = try await MailAIService.shared.priorityBrief(unreadThreads: storage.threads.filter { !$0.isRead })
                await MainActor.run {
                    self.prioritySummary = summary
                    self.isPrioritizing = false
                }
            } catch {
                await MainActor.run {
                    self.prioritySummary = "Unable to generate a priority brief right now."
                    self.isPrioritizing = false
                }
            }
        }
    }

    private func toolbarAction() {
        if filter == .unread {
            runCatchUp()
        } else {
            showingCompose = true
        }
    }

    private func fallbackUID(from string: String) -> Int {
        let value = string.hashValue
        return value == Int.min ? 0 : abs(value)
    }
}

struct MailThreadRow: View {
    let thread: MailThread

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(thread.isRead ? Color.gray.opacity(0.25) : Color.blue.opacity(0.2))
                .frame(width: 38, height: 38)
                .overlay(
                    Text(String((thread.participants.first ?? "?").prefix(1)).uppercased())
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(thread.isRead ? .secondary : .blue)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(thread.participants.first ?? "Unknown")
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(thread.lastMessageDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(thread.subject)
                    .font(.subheadline)
                    .fontWeight(thread.isRead ? .regular : .semibold)
                    .lineLimit(1)

                Text(thread.snippet.isEmpty ? "No preview available" : thread.snippet)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 10)
    }
}
