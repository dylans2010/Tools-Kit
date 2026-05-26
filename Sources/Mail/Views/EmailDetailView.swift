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

    // Sheet states
    @State private var showingInspector = false
    @State private var showingAIPanel = false
    @State private var showingInsights = false
    @State private var showingRelationship = false
    @State private var selectedContentTab: ContentTab = .body

    init(viewModel: MailViewModel, email: EmailMessage, account: MailAccount? = nil) {
        self.viewModel = viewModel
        self.email = email
        self.account = account
    }

    private enum ContentTab: String, CaseIterable {
        case body = "Content"
        case ai = "AI Tools"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            headerBar

                            subjectAndToCards

                            Picker("Tab", selection: $selectedContentTab) {
                                ForEach(ContentTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)

                            switch selectedContentTab {
                            case .body:
                                emailBodyContent(geo: geo)
                            case .ai:
                                aiToolsContent
                            }

                            if !resolvedEmail.attachments.isEmpty {
                                attachmentsSection
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(16)
                    }
                }

                VStack {
                    Spacer()
                    bottomActions
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button { showingInspector = true } label: {
                        Image(systemName: "info.circle")
                    }

                    Menu {
                        Button { showReplyComposer = true } label: {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                        }
                        .disabled(account == nil)

                        Button { showingRelationship = true } label: {
                            Label("Relationship Intel", systemImage: "person.text.rectangle")
                        }

                        Button { showingInsights = true } label: {
                            Label("AI Insights", systemImage: "brain.head.profile")
                        }

                        Divider()

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
        .sheet(isPresented: $showingAIPanel) {
            aiResultsSheet
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingInsights) {
            insightsSheet
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingRelationship) {
            NavigationStack {
                RelationshipInsightsPanel(email: email.sender)
            }
            .presentationDetents([.large])
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

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(Text(resolvedEmail.sender.prefix(1).uppercased()).bold().foregroundColor(.accentColor))

            VStack(alignment: .leading, spacing: 2) {
                Text(resolvedEmail.sender)
                    .font(.headline)
                Text("To: Me")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(resolvedEmail.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }

    private var subjectAndToCards: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Subject")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(resolvedEmail.subject)
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)

            // To field is not explicitly in EmailMessage but we can show it if we had it.
            // Using placeholder or sender for now if needed, but following prompt style.
        }
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachments")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(resolvedEmail.attachments) { attachment in
                        VStack {
                            Image(systemName: "doc.fill")
                                .font(.title)
                            Text(attachment.filename)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 16) {
            Button {
                showReplyComposer = true
            } label: {
                Text("Reply")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(16)
            }
            .disabled(account == nil)

            Button {
                showingInsights = true
            } label: {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Button {
                Task { await archiveEmail() }
            } label: {
                Image(systemName: "archivebox")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Button(role: .destructive) {
                Task { await deleteEmail() }
            } label: {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Email Body Content (full-screen rendering)

    @ViewBuilder
    private func emailBodyContent(geo: GeometryProxy) -> some View {
        VStack {
            if let content = renderContent(from: resolvedEmail) {
                if content.hasHTML, let html = content.htmlBody {
                    MailWebView(htmlString: html, dynamicHeight: $bodyWebViewHeight)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 400)
                        .background(Color.white)
                        .cornerRadius(12)
                } else if let plain = content.plainBody {
                    Text(plain)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .textSelection(.enabled)
                }
            } else {
                ProgressView("Loading…")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - AI Tools Content

    private var aiToolsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                aiActionsGrid

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

                if let error = actionError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
    }

    // MARK: - AI Actions Grid

    private var aiActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            aiActionTile(title: "Summarize", icon: "text.justify.leading", color: .blue) { runAIFeature(.summary) }
            aiActionTile(title: "Action Items", icon: "checklist", color: .green) { runAIFeature(.actionItems) }
            aiActionTile(title: "Tone Analysis", icon: "waveform", color: .purple) { runAIFeature(.tone) }
            aiActionTile(title: "Draft Reply", icon: "pencil.and.outline", color: .orange) { runAIFeature(.replyDraft) }
        }
    }

    private func aiActionTile(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isSummarizing)
    }

    // MARK: - AI Results Sheet

    private var aiResultsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
                }
                .padding()
            }
            .navigationTitle("AI Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingAIPanel = false }.bold()
                }
            }
        }
    }

    // MARK: - Insights Sheet

    private var insightsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    intelligencePanels
                }
                .padding()
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingInsights = false }.bold()
                }
            }
        }
    }

    // MARK: - Loading

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

    // MARK: - Intelligence Panels

    private var intelligenceThread: MailThread {
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
        return MailThread(
            id: String(resolved.uid),
            subject: resolved.subject,
            messages: [mailMessage],
            lastMessageDate: resolved.date
        )
    }

    @ViewBuilder
    private var intelligencePanels: some View {
        intelligenceContent(for: intelligenceThread)
    }

    @ViewBuilder
    private func intelligenceContent(for thread: MailThread) -> some View {
        EmailInsightPanel(thread: thread)

        if thread.subject.lowercased().contains("negotiation") || thread.subject.lowercased().contains("offer") {
            NegotiationAssistantPanel(thread: thread)
        }

        KnowledgeExtractionPanel(thread: thread)
    }

    // MARK: - Helpers

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
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    UIPasteboard.general.string = content
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
            }

            markdownText(content, font: .subheadline)
                .textSelection(.enabled)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
