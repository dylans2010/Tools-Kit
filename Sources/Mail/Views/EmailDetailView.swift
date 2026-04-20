import SwiftUI
import WebKit

struct EmailDetailView: View {
    @ObservedObject var viewModel: MailViewModel
    let email: EmailMessage
    var account: MailAccount?

    @Environment(\.dismiss) private var dismiss

    @State private var bodyWebViewHeight: CGFloat = 320
    @State private var showReplyComposer = false
    @State private var summary = ""
    @State private var isSummarizing = false
    @State private var actionError: String?

    init(viewModel: MailViewModel, email: EmailMessage, account: MailAccount? = nil) {
        self.viewModel = viewModel
        self.email = email
        self.account = account
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(resolvedEmail.subject)
                        .font(.title3.bold())
                    Text(resolvedEmail.sender)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if isSummarizing {
                        ProgressView("Summarizing…")
                    }

                    if !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Summary", systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.95))
                            markdownText(summary, font: .subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.82), Color.red.opacity(0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }

                    contentView(minHeight: max(geo.size.height * 0.4, 220))

                    if let actionError {
                        Text(actionError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if account == nil {
                        Text("Connect a mail account to enable Reply, Delete, and Archive actions.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            summarize()
                        } label: {
                            Label("Summarize", systemImage: "text.justify.leading")
                        }

                        Button {
                            showReplyComposer = true
                        } label: {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                        }
                        .disabled(account == nil)

                        Button {
                            Task { await archiveEmail() }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }

                        Button(role: .destructive) {
                            Task { await deleteEmail() }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fullScreenCover(isPresented: $showReplyComposer) {
                if let account {
                    EmailComposingView(
                        account: account,
                        replyTo: MailMessage(
                            id: String(resolvedEmail.uid),
                            threadId: String(resolvedEmail.uid),
                            from: resolvedEmail.sender,
                            to: [],
                            cc: [],
                            bcc: [],
                            subject: resolvedEmail.subject,
                            body: resolvedEmail.body ?? resolvedEmail.preview,
                            htmlBody: resolvedEmail.htmlBody,
                            date: resolvedEmail.date,
                            isRead: resolvedEmail.isRead,
                            isStarred: false,
                            attachments: []
                        )
                    )
                }
            }
            .task {
                if resolvedEmail.body == nil && resolvedEmail.htmlBody == nil {
                    viewModel.loadBody(for: email)
                }
            }
        }
    }

    private func contentView(minHeight: CGFloat) -> some View {
        Group {
            if let content = renderContent(from: resolvedEmail) {
                if content.hasHTML, let html = content.htmlBody {
                    MailWebView(htmlString: html, dynamicHeight: $bodyWebViewHeight)
                        .frame(height: max(bodyWebViewHeight, minHeight))
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let plain = content.plainBody {
                    ScrollView(.vertical, showsIndicators: false) {
                        markdownText(plain)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: minHeight, alignment: .topLeading)
                }
            } else {
                ProgressView("Loading Body...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            }
        }
    }
    
    @ViewBuilder
    private func markdownText(_ source: String, font: Font = .body) -> some View {
        if let attributed = try? AttributedString(
            markdown: source,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            Text(attributed)
                .font(font)
        } else {
            Text(source)
                .font(font)
        }
    }

    private var resolvedEmail: EmailMessage {
        viewModel.emails.first(where: { $0.uid == email.uid }) ?? email
    }

    private func summarize() {
        guard !isSummarizing else { return }
        isSummarizing = true
        actionError = nil
        summary = ""

        Task {
            do {
                let input = resolvedEmail.body ?? resolvedEmail.preview
                let result = try await AIService.shared.summarize(text: input)
                await MainActor.run {
                    summary = result
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

    private func deleteEmail() async {
        guard let account else {
            actionError = "A linked account is required to delete this email."
            return
        }
        do {
            try await providerDelete(account: account, messageID: String(email.uid))
            if let idx = viewModel.emails.firstIndex(where: { $0.uid == email.uid }) {
                viewModel.emails.remove(at: idx)
            }
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func archiveEmail() async {
        guard let account else {
            actionError = "A linked account is required to archive this email."
            return
        }
        do {
            try await providerArchiveMarkRead(account: account, messageID: String(email.uid))
            if let idx = viewModel.emails.firstIndex(where: { $0.uid == email.uid }) {
                viewModel.emails[idx].isRead = true
            }
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func renderContent(from message: EmailMessage) -> RenderedMailContent? {
        if let html = message.htmlBody {
            return MailContentRenderer.render(htmlBody: html, plainBody: message.body ?? message.preview)
        }

        if let body = message.body {
            let parsed = MailMIMEParser.parse(body)
            let rendered = parsed.isEmpty ? MailContentRenderer.render(htmlBody: nil, plainBody: body) : MailContentRenderer.render(from: parsed)
            return rendered.hasHTML || rendered.plainBody != nil ? rendered : nil
        }

        return MailContentRenderer.render(htmlBody: nil, plainBody: message.preview)
    }

    private func providerDelete(account: MailAccount, messageID: String) async throws {
        switch account.providerType {
        case .gmail:
            try await GmailService(
                accountId: account.id,
                fallbackAccessToken: account.accessToken,
                fallbackRefreshToken: account.refreshToken,
                fallbackEmail: account.emailAddress
            ).deleteMessage(id: messageID)
        case .outlook:
            try await OutlookProvider().deleteMessage(session: providerSession(account: account), id: messageID)
        case .yahoo:
            try await YahooMailProvider().deleteMessage(session: providerSession(account: account), id: messageID)
        case .proton:
            try await ProtonMailProvider().deleteMessage(session: providerSession(account: account), id: messageID)
        case .imap, .icloud:
            try await IMAPProvider().deleteMessage(session: providerSession(account: account), id: messageID)
        }
    }

    private func providerArchiveMarkRead(account: MailAccount, messageID: String) async throws {
        switch account.providerType {
        case .gmail:
            try await GmailService(
                accountId: account.id,
                fallbackAccessToken: account.accessToken,
                fallbackRefreshToken: account.refreshToken,
                fallbackEmail: account.emailAddress
            ).markMessageRead(id: messageID)
        case .outlook:
            try await OutlookProvider().markRead(session: providerSession(account: account), id: messageID)
        case .yahoo:
            try await YahooMailProvider().markRead(session: providerSession(account: account), id: messageID)
        case .proton:
            try await ProtonMailProvider().markRead(session: providerSession(account: account), id: messageID)
        case .imap, .icloud:
            try await IMAPProvider().markRead(session: providerSession(account: account), id: messageID)
        }
    }

    private func providerSession(account: MailAccount) -> MailSession {
        MailSession(
            id: account.id,
            provider: account.providerType,
            email: account.emailAddress,
            displayName: account.displayName,
            accessToken: account.accessToken,
            refreshToken: account.refreshToken,
            imapHost: account.imapHost ?? "imap.mail.me.com",
            imapPort: account.imapPort ?? 993,
            smtpHost: account.smtpHost ?? "smtp.mail.me.com",
            smtpPort: account.smtpPort ?? 587
        )
    }
}
