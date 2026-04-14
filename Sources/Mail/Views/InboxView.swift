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
                        // toggle star
                    } label: {
                        Label("Star", systemImage: thread.messages.first?.isStarred == true ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        // delete
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        // mark read/unread
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
        .onAppear(perform: loadLocal)
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
