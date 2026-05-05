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
    @State private var actionItems = ""
    @State private var toneAnalysis = ""
    @State private var draftReply = ""
    @State private var isRunningAIFeature = false
    @State private var actionError: String?
    @State private var showingInspector = false

    init(viewModel: MailViewModel, email: EmailMessage, account: MailAccount? = nil) {
        self.viewModel = viewModel
        self.email = email
        self.account = account
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color.workspaceBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                            .padding(18)

                        VStack(alignment: .leading, spacing: 18) {
                            aiActionsBar

                            if isSummarizing || isRunningAIFeature {
                                loadingIndicator
                            }

                            if !summary.isEmpty {
                                aiResultCard(title: "AI Summary", icon: "sparkles", content: summary)
                            }

                            if !actionItems.isEmpty {
                                aiResultCard(title: "Action Items", icon: "checklist", content: actionItems)
                            }

                            if !toneAnalysis.isEmpty {
                                aiResultCard(title: "Tone Insights", icon: "waveform.and.magnifyingglass", content: toneAnalysis)
                            }

                            if !draftReply.isEmpty {
                                aiResultCard(title: "Reply Draft", icon: "arrowshape.turn.up.left.2", content: draftReply)
                            }

                            // Advanced Intelligence Panels
                            intelligencePanels
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)

                        contentView(minHeight: max(geo.size.height - 200, 400))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingInspector = true
                        } label: {
                            Image(systemName: "info.circle")
                        }

                        Menu {
                            Button {
                                showReplyComposer = true
                            } label: {
                                Label("Reply", systemImage: "arrowshape.turn.up.left")
                            }
                            .disabled(account == nil)

                            NavigationLink(destination: RelationshipInsightsPanel(email: email.sender)) {
                                Label("Relationship Intel", systemImage: "person.text.rectangle")
                            }

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
            }
            .sheet(isPresented: $showingInspector) {
                MetadataInspectorView(email: email)
                    .presentationDetents([.medium, .large])
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(resolvedEmail.subject)
                .font(.title2.bold())
                .foregroundStyle(.white)

            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(Text(resolvedEmail.sender.prefix(1).uppercased()).font(.caption.bold()))

                VStack(alignment: .leading, spacing: 2) {
                    Text(resolvedEmail.sender)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(resolvedEmail.date.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var aiActionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                aiActionButton(title: "Summarize", icon: "text.justify.leading", action: { runAIFeature(.summary) })
                aiActionButton(title: "Action Items", icon: "checklist", action: { runAIFeature(.actionItems) })
                aiActionButton(title: "Tone", icon: "waveform", action: { runAIFeature(.tone) })
                aiActionButton(title: "Draft Reply", icon: "pencil.and.outline", action: { runAIFeature(.replyDraft) })
            }
        }
    }

    private func aiActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var loadingIndicator: some View {
        HStack {
            ProgressView()
                .tint(.purple)
            Text("AI Is Processing...")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var intelligencePanels: some View {
        let resolved = resolvedEmail
        let mailMessage = MailMessage(
            id: String(resolved.uid),
            threadId: String(resolved.uid),
            from: resolved.sender,
            to: [],
            cc: [],
            bcc: [],
            subject: resolved.subject,
            body: resolved.body ?? resolved.preview,
            htmlBody: resolved.htmlBody,
            date: resolved.date,
            isRead: resolved.isRead,
            isStarred: false,
            attachments: []
        )
        let thread = MailThread(
            id: String(resolved.uid),
            subject: resolved.subject,
            messages: [mailMessage],
            lastMessageDate: resolved.date
        )
        EmailInsightPanel(thread: thread)

        if thread.subject.lowercased().contains("negotiation") || thread.subject.lowercased().contains("offer") {
            NegotiationAssistantPanel(thread: thread)
        }

        KnowledgeExtractionPanel(thread: thread)
    }

    private func contentView(minHeight: CGFloat) -> some View {
        Group {
            if let content = renderContent(from: resolvedEmail) {
                if content.hasHTML, let html = content.htmlBody {
                    MailWebView(htmlString: html, dynamicHeight: $bodyWebViewHeight)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: minHeight)
                        .background(Color.white) // Typical email background
                } else if let plain = content.plainBody {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider().background(Color.white.opacity(0.1))
                        Text(plain)
                            .font(.body)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: minHeight, alignment: .topLeading)
                }
            } else {
                ProgressView("Loading Body...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
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

    private enum EmailAIFeature {
        case summary, actionItems, tone, replyDraft
    }

    private func runAIFeature(_ feature: EmailAIFeature) {
        guard !isSummarizing else { return }
        isSummarizing = true
        isRunningAIFeature = feature != .summary
        actionError = nil

        Task {
            do {
                let input = normalizedEmailBody
                let result: String
                switch feature {
                case .summary:
                    result = try await AIService.shared.summarizeEmail(text: input)
                case .actionItems:
                    result = try await AIService.shared.extractEmailActionItems(text: input)
                case .tone:
                    result = try await AIService.shared.assessEmailTone(text: input)
                case .replyDraft:
                    result = try await AIService.shared.draftReply(
                        to: input,
                        from: resolvedEmail.sender,
                        subject: resolvedEmail.subject
                    )
                }
                await MainActor.run {
                    switch feature {
                    case .summary: summary = result
                    case .actionItems: actionItems = result
                    case .tone: toneAnalysis = result
                    case .replyDraft: draftReply = result
                    }
                    isSummarizing = false
                    isRunningAIFeature = false
                }
            } catch {
                await MainActor.run {
                    actionError = error.localizedDescription
                    isSummarizing = false
                    isRunningAIFeature = false
                }
            }
        }
    }

    private var normalizedEmailBody: String {
        if let content = renderContent(from: resolvedEmail), let plain = content.plainBody, !plain.isEmpty {
            return plain
        }
        return resolvedEmail.body ?? resolvedEmail.preview
    }

    private func aiResultCard(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))

            markdownText(content, font: .subheadline)
                .foregroundStyle(.white.opacity(0.96))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
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
            try await GmailProvider().deleteMessage(session: providerSession(account: account), id: messageID)
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
            try await GmailProvider().markRead(session: providerSession(account: account), id: messageID)
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
            accessTokenExpiration: account.accessTokenExpiration,
            imapHost: account.imapHost ?? "imap.mail.me.com",
            imapPort: account.imapPort ?? 993,
            smtpHost: account.smtpHost ?? "smtp.mail.me.com",
            smtpPort: account.smtpPort ?? 587
        )
    }
}
