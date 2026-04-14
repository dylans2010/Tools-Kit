import SwiftUI

struct InboxView: View {
    let account: MailAccount
    let folder: MailFolder
    var filter: InboxFilter = .all

    enum InboxFilter {
        case all, unread
    }

    @StateObject private var syncService = MailSyncService.shared
    @State private var threads: [MailThread] = []
    @State private var searchText = ""
    @State private var showingCompose = false
    @State private var catchUpSummary: String?
    @State private var isSummarizing = false

    var body: some View {
        List {
            // Sync status banner
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

            if filter == .unread && catchUpSummary == nil && !threads.isEmpty {
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

            ForEach(filteredThreads) { thread in
                NavigationLink(destination: MailThreadView(account: account, thread: thread)) {
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
            }
        }
        .navigationTitle(filter == .unread ? "Catch Up" : folder.name)
        .searchable(text: $searchText)
        .refreshable {
            await syncService.sync(account: account, folder: folder)
            loadLocal()
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
        .onAppear {
            loadLocal()
            if threads.isEmpty {
                Task {
                    await syncService.sync(account: account, folder: folder)
                    loadLocal()
                }
            }
        }
    }

    private var filteredThreads: [MailThread] {
        var result = threads
        if filter == .unread {
            result = threads.filter { !$0.isRead }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.subject.localizedCaseInsensitiveContains(searchText) || $0.snippet.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private func loadLocal() {
        threads = MailStorageService.shared.loadThreads(for: "\(account.id)_\(folder.id)")
    }

    private func toggleRead(_ thread: MailThread) {
        guard let idx = threads.firstIndex(where: { $0.id == thread.id }) else { return }
        let targetRead = !thread.isRead
        for msgIdx in threads[idx].messages.indices {
            threads[idx].messages[msgIdx].isRead = targetRead
        }
        MailStorageService.shared.saveThreads(threads, for: "\(account.id)_\(folder.id)")
    }

    private func toggleStar(_ thread: MailThread) {
        guard let idx = threads.firstIndex(where: { $0.id == thread.id }) else { return }
        let currentlyStarred = threads[idx].messages.first?.isStarred ?? false
        for msgIdx in threads[idx].messages.indices {
            threads[idx].messages[msgIdx].isStarred = !currentlyStarred
        }
        MailStorageService.shared.saveThreads(threads, for: "\(account.id)_\(folder.id)")
    }

    private func deleteThread(_ thread: MailThread) {
        threads.removeAll { $0.id == thread.id }
        MailStorageService.shared.saveThreads(threads, for: "\(account.id)_\(folder.id)")
    }

    private func runCatchUp() {
        isSummarizing = true
        Task {
            do {
                let summary = try await MailAIService.shared.catchUp(unreadThreads: threads.filter { !$0.isRead })
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
