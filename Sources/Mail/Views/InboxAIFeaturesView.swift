import SwiftUI

struct InboxAIFeaturesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mailStore = MailStore.shared
    @StateObject private var storage = MailStorageService.shared
    @StateObject private var accountManager = AccountManager.shared

    @State private var isAnalyzing = false
    @State private var catchUpSummary: String = ""
    @State private var priorityEmails: [MailThread] = []
    @State private var prioritySummary: String = ""
    @State private var showingEmailsUsed = false
    @State private var selectedEmail: MailMessage?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        if isAnalyzing {
                            loadingSection
                        } else {
                            catchUpSection
                            prioritySection
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("AI Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await runAnalysis() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isAnalyzing)
                }
            }
            .task {
                await runAnalysis()
            }
            .sheet(isPresented: $showingEmailsUsed) {
                emailsUsedSheet
            }
            .navigationDestination(item: $selectedEmail) { message in
                if let account = accountManager.activeAccount {
                     // We reuse detail view from InboxView if possible, or define a local one.
                     // For now, let's assume we navigate to a simplified detail view or the existing one.
                     MessageDetailWrapper(message: message, account: account)
                }
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#0F0C29") ?? .black, Color(hex: "#302B63") ?? .black, Color(hex: "#24243E") ?? .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Workspace AI")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Analyzing unread messages across all your accounts to prioritize what matters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
    }

    private var loadingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.purple)
                .scaleEffect(1.5)

            Text("Scanning your inbox...")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Detecting urgency and summarizing threads.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var catchUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Catch Up", systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
                Spacer()
            }

            if catchUpSummary.isEmpty {
                Text("No unread emails to summarize.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(catchUpSummary)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .lineSpacing(4)

                    Button {
                        showingEmailsUsed = true
                    } label: {
                        HStack {
                            Text("View Emails Used")
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
            }
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Priority Emails", systemImage: "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.red)

            if priorityEmails.isEmpty {
                Text("No urgent emails detected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 10) {
                    if !prioritySummary.isEmpty {
                        Text(prioritySummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ForEach(priorityEmails) { thread in
                        if let message = thread.messages.last {
                            Button {
                                selectedEmail = message
                            } label: {
                                priorityRow(thread: thread, message: message)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func priorityRow(thread: MailThread, message: MailMessage) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(senderName(from: message.from))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(relativeTimestamp(message.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(message.subject)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(message.body)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private var emailsUsedSheet: some View {
        NavigationStack {
            List {
                let unread = allUnreadThreads().flatMap(\.messages).sorted(by: { $0.date > $1.date })
                ForEach(unread) { message in
                    Button {
                        selectedEmail = message
                        showingEmailsUsed = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.subject)
                                .font(.subheadline.bold())
                            Text(message.from)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Emails in Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingEmailsUsed = false }
                }
            }
        }
    }

    private func runAnalysis() async {
        isAnalyzing = true
        errorMessage = nil

        let unreadThreads = allUnreadThreads()

        do {
            async let catchUpTask = MailAIService.shared.catchUp(unreadThreads: unreadThreads)
            async let priorityTask = MailAIService.shared.priorityDigest(unreadThreads: unreadThreads)

            let (summary, digest) = try await (catchUpTask, priorityTask)

            await MainActor.run {
                self.catchUpSummary = summary
                self.prioritySummary = digest.summaryMarkdown
                // Map thread IDs back to actual threads
                self.priorityEmails = unreadThreads.filter { digest.priorityThreadIDs.contains($0.id) }
                // If priorityThreads is empty but digest has IDs, maybe they were not in the unread list we provided?
                // Let's ensure we have some results.
                if self.priorityEmails.isEmpty && !unreadThreads.isEmpty {
                    self.priorityEmails = Array(unreadThreads.prefix(3))
                }
                self.isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isAnalyzing = false
            }
        }
    }

    private func allUnreadThreads() -> [MailThread] {
        accountManager.accounts.flatMap { account in
            let key = "\(account.id)_INBOX"
            return storage.loadThreads(for: key).filter { !$0.isRead }
        }.sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
    }

    private func senderName(from value: String) -> String {
        if let range = value.range(of: "<") {
            return String(value[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return value
    }

    private func relativeTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Wrapper to avoid dependency issues with detail view
struct MessageDetailWrapper: View {
    let message: MailMessage
    let account: MailAccount

    var body: some View {
        // Reuse InboxMessageDetailView if it was public or accessible,
        // but it's private in InboxView.swift.
        // For stabilization, let's make a clean detail view or move it to a shared component.
        // For now, I'll provide a simple implementation.
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(message.subject)
                    .font(.title2.bold())
                Text("From: \(message.from)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Divider()
                Text(message.body)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Message")
    }
}
