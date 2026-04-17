import SwiftUI
import WebKit

struct MailThreadView: View {
    @ObservedObject var viewModel: MailViewModel
    let email: EmailMessage

    @State private var showingReply = false
    @State private var aiSummary: String?
    @State private var isAISummarizing = false
    @State private var aiReplyDraft: String?
    @State private var isGeneratingReply = false
    @State private var aiErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection

                // Body — use MailContentRenderer for HTML or plain-text
                bodySection
                    .padding(.top, 8)

                if let aiErrorMessage {
                    aiErrorCard(aiErrorMessage)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                // AI Summary card
                if let summary = aiSummary {
                    aiSummaryCard(summary)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                // AI Reply draft
                if let draft = aiReplyDraft {
                    aiReplyCard(draft)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                Spacer(minLength: 80)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingReply = true } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                    }
                    Button(action: summarizeWithAI) {
                        Label("Summarize", systemImage: "sparkles")
                    }
                    Button(action: generateAIReply) {
                        Label("Reply with AI", systemImage: "sparkle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            replyBar
        }
        .sheet(isPresented: $showingReply) {
            replySheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(email.subject)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 16)

            HStack(spacing: 10) {
                Circle()
                    .fill(avatarColor(for: email.sender))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(email.sender.prefix(1).uppercased())
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(email.sender)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(email.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Body

    @ViewBuilder
    private var bodySection: some View {
        if let content = renderedContent {
            if content.hasHTML, let html = content.htmlBody {
                MailWebView(htmlString: html)
                    .frame(minHeight: 300)
                    .padding(.horizontal)
            } else if let plain = content.plainBody {
                Text(plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)
            }
        } else {
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            .onAppear { viewModel.loadBody(for: email) }
        }
    }

    // MARK: - Reply Bar

    private var replyBar: some View {
        HStack(spacing: 12) {
            Button { showingReply = true } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }

            Button(action: summarizeWithAI) {
                if isAISummarizing {
                    ProgressView().tint(.white)
                } else {
                    Label("Summarize", systemImage: "sparkles")
                        .font(.subheadline.weight(.medium))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isAISummarizing)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Material.bar)
    }

    // MARK: - Reply Sheet

    @ViewBuilder
    private var replySheet: some View {
        // Build a MailMessage from EmailMessage for the reply
        let msg = MailMessage(
            id: email.id.uuidString,
            threadId: UUID().uuidString,
            from: email.sender,
            to: [],
            cc: [],
            bcc: [],
            subject: email.subject,
            body: email.body ?? "",
            htmlBody: nil,
            date: email.date,
            isRead: true,
            isStarred: false,
            attachments: []
        )
        // Use the first enabled saved account or a placeholder
        let account = MailStorageService.shared.loadAccounts().first
            ?? MailAccount(id: UUID(), email: "", provider: .iCloud, isEnabled: true)
        EmailComposingView(account: account, replyTo: msg)
    }

    // MARK: - AI Cards

    private func aiSummaryCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Summary")
                    .font(.headline)
                    .foregroundColor(.purple)
                Spacer()
                Button { aiSummary = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            Text(summary)
                .font(.subheadline)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func aiReplyCard(_ draft: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkle")
                    .foregroundColor(.blue)
                Text("AI Reply Draft")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Button { aiReplyDraft = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            Text(draft)
                .font(.subheadline)
                .lineSpacing(4)

            HStack {
                Button {
                    UIPasteboard.general.string = draft
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)

                Button { showingReply = true } label: {
                    Label("Use as Reply", systemImage: "arrowshape.turn.up.left")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func aiErrorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                aiErrorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - AI Actions

    private func summarizeWithAI() {
        guard !isAISummarizing else { return }
        isAISummarizing = true
        aiErrorMessage = nil

        let thread = MailThread(
            id: email.id.uuidString,
            subject: email.subject,
            messages: [
                MailMessage(
                    id: email.id.uuidString,
                    threadId: UUID().uuidString,
                    from: email.sender,
                    to: [],
                    cc: [],
                    bcc: [],
                    subject: email.subject,
                    body: email.body ?? email.preview,
                    htmlBody: nil,
                    date: email.date,
                    isRead: email.isRead,
                    isStarred: false,
                    attachments: []
                )
            ],
            lastMessageDate: email.date
        )

        Task {
            do {
                let summary = try await MailAIService.shared.summarizeThread(thread)
                await MainActor.run {
                    aiSummary = summary
                    isAISummarizing = false
                }
            } catch {
                await MainActor.run {
                    aiErrorMessage = error.localizedDescription
                    isAISummarizing = false
                }
            }
        }
    }

    private func generateAIReply() {
        guard !isGeneratingReply else { return }
        isGeneratingReply = true
        aiErrorMessage = nil

        let msg = MailMessage(
            id: email.id.uuidString,
            threadId: UUID().uuidString,
            from: email.sender,
            to: [],
            cc: [],
            bcc: [],
            subject: email.subject,
            body: email.body ?? email.preview,
            htmlBody: nil,
            date: email.date,
            isRead: true,
            isStarred: false,
            attachments: []
        )

        Task {
            do {
                let draft = try await MailAIService.shared.generateReply(for: msg, context: "")
                await MainActor.run {
                    aiReplyDraft = draft
                    isGeneratingReply = false
                }
            } catch {
                await MainActor.run {
                    aiErrorMessage = error.localizedDescription
                    isGeneratingReply = false
                }
            }
        }
    }

    // MARK: - Helpers

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .teal, .indigo]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    private var renderedContent: RenderedMailContent? {
        if let html = email.htmlBody {
            return MailContentRenderer.render(htmlBody: html, plainBody: email.body ?? email.preview)
        }
        if let body = email.body {
            let parsed = MailMIMEParser.parse(body)
            return parsed.isEmpty ? MailContentRenderer.render(htmlBody: nil, plainBody: body) : MailContentRenderer.render(from: parsed)
        }
        return nil
    }
}
