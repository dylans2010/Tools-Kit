import SwiftUI
import WebKit

struct InboxDetailView: View {
    let account: MailAccount
    let message: MailMessage

    @Environment(\.dismiss) private var dismiss

    @State private var showReply = false
    @State private var isSummarizing = false
    @State private var summary: String?
    @State private var actionError: String?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    subjectSection

                    if isSummarizing {
                        summarizingIndicator
                    }

                    if let summary, !summary.isEmpty {
                        summarySection(summary: summary)
                    }

                    bodyContainer

                    if !message.attachments.isEmpty {
                        attachmentsSection
                    }

                    if let actionError {
                        Text(actionError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                    }

                    Spacer(minLength: 120)
                }
                .padding(16)
            }

            VStack {
                Spacer()
                bottomActions
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showReply) {
            EmailComposingView(account: account, replyTo: message)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(message.from.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.accentColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(senderName(from: message.from))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(message.from)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(message.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.subject)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .padding(.bottom, 4)
    }

    private var bodyContainer: some View {
        VStack(alignment: .leading) {
            if let htmlBody = message.htmlBody, !htmlBody.isEmpty {
                MessageWebView(html: htmlBody)
                    .frame(minHeight: 400)
            } else {
                Text(message.body)
                    .font(.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attachments")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(message.attachments) { attachment in
                        VStack(spacing: 8) {
                            Image(systemName: attachmentIcon(attachment.contentType))
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            Text(attachment.fileName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                        .padding(12)
                        .frame(width: 100, height: 100)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                showReply = true
            } label: {
                HStack {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                    Text("Reply")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            actionButton(icon: "sparkles", color: .purple) { summarize() }
            actionButton(icon: "archivebox", color: .blue) { Task { await archiveMessage() } }
            actionButton(icon: "trash", color: .red) { Task { await deleteMessage() } }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 52, height: 52)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())
        }
    }

    private var summarizingIndicator: some View {
        HStack {
            ProgressView()
                .tint(.purple)
            Text("AI Summarizing...")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func summarySection(summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI Summary", systemImage: "sparkles")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Spacer()
                Button {
                    UIPasteboard.general.string = summary
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
            }

            Text(summary)
                .font(.subheadline)
                .lineSpacing(2)
        }
        .padding(14)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Logic

    private func senderName(from value: String) -> String {
        if let range = value.range(of: "<") {
            return String(value[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return value
    }

    private func attachmentIcon(_ contentType: String) -> String {
        if contentType.hasPrefix("image/") { return "photo" }
        if contentType.contains("pdf") { return "doc.richtext" }
        return "doc.fill"
    }

    private func summarize() {
        guard !isSummarizing else { return }
        isSummarizing = true
        summary = nil
        actionError = nil

        Task {
            do {
                let input = message.body.isEmpty ? message.subject : message.body
                let response = try await AIService.shared.processText(
                    prompt: """
                    Summarize this email in 3-4 short bullets. Focus on action items.
                    Email:
                    \(input)
                    """,
                    systemPrompt: "You are a concise executive email summarizer."
                )
                await MainActor.run {
                    summary = response
                    isSummarizing = false
                }
            } catch {
                await MainActor.run {
                    actionError = error.localizedDescription
                    isSummarizing = false
                }
            }
        }
    }

    private func deleteMessage() async {
        do {
            try await providerDelete(account: account, messageID: message.id)
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func archiveMessage() async {
        do {
            try await providerMarkReadForArchive(account: account, messageID: message.id)
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func providerDelete(account: MailAccount, messageID: String) async throws {
        switch account.providerType {
        case .gmail:
            try await GmailProvider().deleteMessage(session: providerSession(), id: messageID)
        case .outlook:
            try await OutlookProvider().deleteMessage(session: providerSession(), id: messageID)
        case .yahoo:
            try await YahooMailProvider().deleteMessage(session: providerSession(), id: messageID)
        case .proton:
            try await ProtonMailProvider().deleteMessage(session: providerSession(), id: messageID)
        case .imap, .icloud:
            try await IMAPProvider().deleteMessage(session: providerSession(), id: messageID)
        }
    }

    private func providerMarkReadForArchive(account: MailAccount, messageID: String) async throws {
        switch account.providerType {
        case .gmail:
            try await GmailProvider().markRead(session: providerSession(), id: messageID)
        case .outlook:
            try await OutlookProvider().markRead(session: providerSession(), id: messageID)
        case .yahoo:
            try await YahooMailProvider().markRead(session: providerSession(), id: messageID)
        case .proton:
            try await ProtonMailProvider().markRead(session: providerSession(), id: messageID)
        case .imap, .icloud:
            try await IMAPProvider().markRead(session: providerSession(), id: messageID)
        }
    }

    private func providerSession() -> MailSession {
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
}

private struct MessageWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let css = """
        <style>
        body { background: transparent; color: #1C1C1E; font-family: -apple-system; font-size: 16px; line-height: 1.5; margin: 0; padding: 0; }
        @media (prefers-color-scheme: dark) { body { color: #F2F2F7; } }
        a { color: #007AFF; }
        </style>
        """
        let document = "<html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"></head><body>\(css)\(html)</body></html>"
        uiView.loadHTMLString(document, baseURL: nil)
    }
}
