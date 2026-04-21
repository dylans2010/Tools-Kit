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
                    VStack(spacing: 20) {
                        headerSection

                        if isAnalyzing {
                            loadingSection
                        } else {
                            catchUpSection
                            prioritySection
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("AI Intelligence")
            .navigationBarTitleDisplayMode(.inline)
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
                .modifier(ModernSymbolEffect(trigger: pulseHeader))

            Text("Workspace AI")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Analyzing only the emails currently loaded in this Inbox screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
        .onAppear { pulseHeader = true }
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
                    .modifier(ModernSymbolEffect(trigger: !catchUpSummary.isEmpty))
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
                    MarkdownTextBlock(text: catchUpSummary)

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
        .padding(16)
        .glassSectionBackground(gradient: [Color.purple.opacity(0.35), Color.blue.opacity(0.2)])
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Priority Emails", systemImage: "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.red)
                .modifier(ModernSymbolEffect(trigger: !priorityEmails.isEmpty))

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
                        MarkdownTextBlock(text: prioritySummary)
                            .padding(12)
                            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
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
        .padding(16)
        .glassSectionBackground(gradient: [Color.red.opacity(0.28), Color.orange.opacity(0.18)])
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
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
        defer { isAnalyzing = false }

        let messages = analyzableMessages()
        guard !messages.isEmpty else {
            catchUpSummary = "No unread emails to summarize."
            prioritySummary = "No urgent emails detected."
            priorityEmails = []
            return
        }

        let analysisInput = messages.prefix(40).map { message in
            """
            Message ID: \(message.id)
            Subject: \(message.subject)
            From: \(message.from)
            Date: \(message.date.formatted(date: .abbreviated, time: .shortened))
            Content: \(message.body.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1000))
            """
        }.joined(separator: "\n\n---\n\n")

        let systemPrompt = """
        You are InboxOps-FT-v3, a fine-tuned inbox triage model.
        You must analyze ALL provided email content exactly as given.
        Strict requirements:
        1) Never invent facts; only use provided content.
        2) Prioritize by urgency, deadline, risk, stakeholder importance, and blocked dependencies.
        3) Detect hidden tasks and explicit asks.
        4) Return concise markdown only.
        5) Keep every sentence actionable and concrete.
        6) If evidence is missing, explicitly write "Unknown from inbox content".
        7) Prefer short bullet points over prose.
        """

        do {
            async let catchUpTask = AIService.shared.processText(
                prompt: """
                Fully analyze the inbox content and return a SHORT markdown briefing with these sections:
                ## TL;DR
                ## Top Priorities (max 5 bullets)
                ## Required Actions Today (max 5 checkboxes)

                Inbox content:\n\(analysisInput)
                """,
                systemPrompt: systemPrompt
            )

            async let priorityTask = AIService.shared.processText(
                prompt: """
                Analyze inbox content and produce a SHORT markdown priority digest.
                Include:
                ## Priority Ranking
                ## Why These Matter
                ## What Can Wait

                Mention message IDs when possible.

                Inbox content:\n\(analysisInput)
                """,
                systemPrompt: systemPrompt
            )

            let (summary, priorityDigest) = try await (catchUpTask, priorityTask)
            catchUpSummary = summary
            prioritySummary = priorityDigest

            let loweredDigest = priorityDigest.lowercased()
            let unreadThreads = inboxThreads
                .filter { !$0.isRead }
                .sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
            let matched = unreadThreads.filter { thread in
                guard let message = thread.messages.last else { return false }
                return loweredDigest.contains(message.id.lowercased()) ||
                    loweredDigest.contains(message.subject.lowercased()) ||
                    loweredDigest.contains(senderName(from: message.from).lowercased())
            }

            priorityEmails = Array((matched.isEmpty ? unreadThreads : matched).prefix(5))
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

private struct ModernSymbolEffect: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.pulse.byLayer, value: trigger)
        } else {
            content
        }
    }
}

private extension View {
    func glassSectionBackground(gradient: [Color]) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(.ultraThinMaterial.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }
}

private struct MessageDetailWrapper: View {
    let message: MailMessage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(message.subject)
                    .font(.title2.bold())
                Text("From: \(message.from)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Divider()
                MarkdownTextBlock(text: message.body)
            }
            .padding()
        }
        .navigationTitle("Message")
    }
}

private struct MarkdownTextBlock: View {
    let text: String

    var body: some View {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedIfPossible)
        ) {
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
