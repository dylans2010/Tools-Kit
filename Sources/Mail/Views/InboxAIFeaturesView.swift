import SwiftUI

struct InboxAIFeaturesView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var storage = MailStorageService.shared

    @State private var isLoading = false
    @State private var priorityDigest: MailAIService.PriorityDigest?
    @State private var catchUpSummary = ""
    @State private var emailsUsed: [UsedEmail] = []
    @State private var showUsedEmails = false
    @State private var selectedUsedEmail: UsedEmail?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Priority Emails") {
                    if isLoading {
                        ProgressView("Analyzing urgency…")
                    }

                    if let digest = priorityDigest {
                        markdownCard(digest.summaryMarkdown)

                        ForEach(priorityEmails) { email in
                            Button {
                                selectedUsedEmail = email
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(email.subject).font(.subheadline.weight(.semibold))
                                    Text(email.from).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } else if !isLoading {
                        Text("No unread emails found.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Catch Up") {
                    if isLoading {
                        ProgressView("Generating summary…")
                    } else if catchUpSummary.isEmpty {
                        Text("Tap Refresh to generate a catch-up summary.")
                            .foregroundStyle(.secondary)
                    } else {
                        markdownCard(catchUpSummary)

                        Button("View Emails Used") {
                            showUsedEmails = true
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Inbox AI Features")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await runAnalysis() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task { await runAnalysis() }
            .sheet(isPresented: $showUsedEmails) {
                NavigationStack {
                    List(emailsUsed) { email in
                        Button {
                            selectedUsedEmail = email
                            showUsedEmails = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(email.subject).font(.subheadline.weight(.semibold))
                                Text(email.from).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .navigationTitle("Emails Used")
                }
            }
            .navigationDestination(item: $selectedUsedEmail) { used in
                InboxMessageDetailView(account: used.account, message: used.message)
            }
        }
    }

    private var priorityEmails: [UsedEmail] {
        guard let ids = priorityDigest?.priorityThreadIDs else { return [] }
        return emailsUsed.filter { ids.contains($0.threadID) }
    }

    @ViewBuilder
    private func markdownCard(_ markdown: String) -> some View {
        if let attr = try? AttributedString(markdown: markdown) {
            Text(attr)
                .padding(.vertical, 6)
        } else {
            Text(markdown)
                .padding(.vertical, 6)
        }
    }

    private func runAnalysis() async {
        isLoading = true
        errorMessage = nil

        do {
            accountManager.refreshAccounts()
            for account in accountManager.accounts {
                await MailSyncService.shared.fetchThreads(account: account, folder: .inbox)
            }

            let data = loadUnreadEmails()
            emailsUsed = data.used

            let digest = try await MailAIService.shared.priorityDigest(unreadThreads: data.threads)
            let summary = try await MailAIService.shared.catchUp(unreadThreads: data.threads)

            priorityDigest = digest
            catchUpSummary = summary
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func loadUnreadEmails() -> (threads: [MailThread], used: [UsedEmail]) {
        var threads: [MailThread] = []
        var used: [UsedEmail] = []

        for account in accountManager.accounts {
            let key = "\(account.id)_INBOX"
            let loaded = storage.loadThreads(for: key)
            let unread = loaded.filter { !$0.isRead }
            threads.append(contentsOf: unread)
            for thread in unread {
                if let latest = thread.messages.last {
                    used.append(UsedEmail(account: account, threadID: thread.id, message: latest))
                }
            }
        }

        return (threads, used.sorted { $0.message.date > $1.message.date })
    }
}

private struct UsedEmail: Identifiable, Hashable {
    let account: MailAccount
    let threadID: String
    let message: MailMessage

    var id: String { message.id }
    var subject: String { message.subject }
    var from: String { message.from }
}
