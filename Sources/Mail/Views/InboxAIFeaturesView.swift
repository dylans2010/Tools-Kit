import SwiftUI

struct InboxAIFeaturesView: View {
    @Environment(\.dismiss) private var dismiss

    let inboxThreads: [MailThread]

    @State private var isAnalyzing = false
    @State private var catchUpSummary: String = ""
    @State private var priorityEmails: [MailThread] = []
    @State private var prioritySummary: String = ""
    @State private var showingEmailsUsed = false
    @State private var selectedEmail: MailMessage?
    @State private var errorMessage: String?
    @State private var pulseHeader = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        if isAnalyzing {
                            loadingSection
                        } else {
                            catchUpSection
                            prioritySection
                        }

                        if let errorMessage {
                            errorCard(errorMessage)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("AI Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.secondary)
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
                MessageDetailWrapper(message: message)
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#090E1F") ?? .black,
                Color.workspaceBackground ?? .black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            MailAITitleHeader(
                title: "Inbox Intelligence",
                subtitle: "Analyzing your recent communications to highlight what matters.",
                symbol: "sparkles",
                symbolSize: 24
            )
            .foregroundStyle(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .leading, endPoint: .trailing))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 24))
    }

    private var loadingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.purple)
                .scaleEffect(1.5)

            Text("Thinking...")
                .font(.headline.bold())
                .foregroundStyle(.white)

            Text("Synthesizing a summary of your inbox.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var catchUpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("The Catch Up", systemImage: "bolt.fill")
                    .font(.headline.bold())
                    .foregroundStyle(.yellow)
                Spacer()
            }

            if catchUpSummary.isEmpty {
                Text("Nothing to report yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    MarkdownTextBlock(text: catchUpSummary)

                    Button {
                        showingEmailsUsed = true
                    } label: {
                        HStack {
                            Text("Source Emails")
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    }
                }
                .padding(18)
                .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("High Priority", systemImage: "exclamationmark.shield.fill")
                .font(.headline.bold())
                .foregroundStyle(.red)

            if priorityEmails.isEmpty {
                Text("All clear. No urgent threads detected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    if !prioritySummary.isEmpty {
                        MarkdownTextBlock(text: prioritySummary)
                            .padding(14)
                            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14))
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
        .padding(20)
        .background(BlurView(style: .systemUltraThinMaterialDark))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func priorityRow(thread: MailThread, message: MailMessage) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(senderName(from: message.from))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Text(relativeTimestamp(message.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(message.subject)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                Text(message.snippet)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var emailsUsedSheet: some View {
        NavigationStack {
            List {
                ForEach(analyzableMessages()) { message in
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
            .navigationTitle("Analyzed Emails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingEmailsUsed = false }
                }
            }
        }
    }

    private func errorCard(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private func runAnalysis() async {
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        let messages = analyzableMessages()
        guard !messages.isEmpty else {
            catchUpSummary = "Your inbox is empty."
            priorityEmails = []
            return
        }

        do {
            let summary = try await MailAIService.shared.catchUp(unreadThreads: inboxThreads)
            let digest = try await MailAIService.shared.priorityDigest(unreadThreads: inboxThreads)

            await MainActor.run {
                catchUpSummary = summary
                prioritySummary = digest.summaryMarkdown
                priorityEmails = inboxThreads.filter { digest.priorityThreadIDs.contains($0.id) }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func analyzableMessages() -> [MailMessage] {
        inboxThreads
            .filter { !$0.isRead }
            .flatMap(\.messages)
            .sorted(by: { $0.date > $1.date })
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
