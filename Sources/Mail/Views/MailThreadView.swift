import SwiftUI
import WebKit

struct MailThreadView: View {
    @ObservedObject var viewModel: MailViewModel
    let email: EmailMessage

    @State private var showingReply = false
    @State private var bodyWebViewHeight: CGFloat = 320
    @State private var aiSummary: String?
    @State private var isAISummarizing = false
    @State private var aiReplyDraft: String?
    @State private var isGeneratingReply = false
    @State private var aiErrorMessage: String?
    @State private var showingInspector = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection

                // AI Tools Bar
                aiToolsBar
                    .padding(.top, 12)

                // Body
                bodySection
                    .padding(.top, 12)

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

                // Advanced Context
                let bodyText = renderedContent?.plainBody ?? email.body ?? email.preview
                let currentMessage = MailMessage(id: email.id.uuidString, threadId: "", from: email.sender, to: [], cc: [], bcc: [], subject: email.subject, body: bodyText, htmlBody: email.htmlBody, date: email.date, isRead: true, isStarred: false, attachments: [])
                let thread = MailThread(id: email.id.uuidString, subject: email.subject, messages: [currentMessage], lastMessageDate: email.date)
                DecisionTimelineViewer(threadID: thread.id)

                if !email.attachments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Attachment Intelligence")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(email.attachments) { attachment in
                            let mailAttachment = MailMessage.MailAttachment(id: attachment.id.uuidString, fileName: attachment.filename, contentType: "application/octet-stream", size: 0)
                            AttachmentIntelligencePanel(attachment: mailAttachment)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 12)
                }

                Spacer(minLength: 80)
            }
        }
        .background(Color.workspaceBackground ?? .black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showingInspector = true
                    } label: {
                        Image(systemName: "info.circle")
                    }

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
        }
        .safeAreaInset(edge: .bottom) {
            replyBar
        }
        .fullScreenCover(isPresented: $showingReply) {
            replySheet
        }
        .sheet(isPresented: $showingInspector) {
            MetadataInspectorView(email: email)
                .presentationDetents([.medium, .large])
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(email.subject)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .padding(.top, 16)

            HStack(spacing: 12) {
                Circle()
                    .fill(avatarColor(for: email.sender))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(email.sender.prefix(1).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(email.sender)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(email.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal)
        .background(Color.workspaceSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var aiToolsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                aiToolButton(title: "Summarize", icon: "sparkles", action: summarizeWithAI, isLoading: isAISummarizing)
                aiToolButton(title: "AI Reply", icon: "pencil.and.outline", action: generateAIReply, isLoading: isGeneratingReply)
            }
            .padding(.horizontal)
        }
    }

    private func aiToolButton(title: String, icon: String, action: @escaping () -> Void, isLoading: Bool) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.caption.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(LinearGradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)], startPoint: .leading, endPoint: .trailing), in: Capsule())
            .foregroundStyle(.white)
        }
        .disabled(isLoading)
    }

    @ViewBuilder
    private var bodySection: some View {
        if let content = renderedContent {
            if content.hasHTML, let html = content.htmlBody {
                MailWebView(htmlString: html, dynamicHeight: $bodyWebViewHeight)
                    .frame(height: bodyWebViewHeight)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal)
            } else if let plain = content.plainBody {
                Text(plain)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
            }
        } else {
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading Content…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            .onAppear { viewModel.loadBody(for: email) }
        }
    }

    private var replyBar: some View {
        HStack(spacing: 12) {
            Button { showingReply = true } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(14)
            }

            Button(action: summarizeWithAI) {
                if isAISummarizing {
                    ProgressView().tint(.white)
                } else {
                    Label("AI Catch Up", systemImage: "sparkles")
                        .font(.subheadline.bold())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .cornerRadius(14)
            .disabled(isAISummarizing)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(BlurView(style: .systemThinMaterialDark))
    }

    @ViewBuilder
    private var replySheet: some View {
        let rendered = renderedContent
        let msg = MailMessage(
            id: email.id.uuidString,
            threadId: UUID().uuidString,
            from: email.sender,
            to: [],
            cc: [],
            bcc: [],
            subject: email.subject,
            body: rendered?.plainBody ?? email.body ?? email.preview,
            htmlBody: email.htmlBody,
            date: email.date,
            isRead: true,
            isStarred: false,
            attachments: []
        )
        let account = MailStorageService.shared.loadAccounts().first
            ?? MailAccount(id: UUID(), email: "", provider: .iCloud, isEnabled: true)
        EmailComposingView(account: account, replyTo: msg)
    }

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
                .foregroundStyle(.white)
        }
        .padding()
        .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.3), lineWidth: 1))
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
                .foregroundStyle(.white)

            HStack {
                Button {
                    UIPasteboard.general.string = draft
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                Button { showingReply = true } label: {
                    Label("Use Draft", systemImage: "arrowshape.turn.up.left")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.3), lineWidth: 1))
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
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func summarizeWithAI() {
        guard !isAISummarizing else { return }
        isAISummarizing = true
        aiErrorMessage = nil

        let bodyText = renderedContent?.plainBody ?? email.body ?? email.preview
        let currentMessage = MailMessage(id: email.id.uuidString, threadId: "", from: email.sender, to: [], cc: [], bcc: [], subject: email.subject, body: bodyText, htmlBody: email.htmlBody, date: email.date, isRead: true, isStarred: false, attachments: [])
        let thread = MailThread(id: email.id.uuidString, subject: email.subject, messages: [currentMessage], lastMessageDate: email.date)

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

        let bodyText = renderedContent?.plainBody ?? email.body ?? email.preview
        let msg = MailMessage(id: email.id.uuidString, threadId: "", from: email.sender, to: [], cc: [], bcc: [], subject: email.subject, body: bodyText, htmlBody: email.htmlBody, date: email.date, isRead: true, isStarred: false, attachments: [])

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
            let rendered = parsed.isEmpty ? MailContentRenderer.render(htmlBody: nil, plainBody: body) : MailContentRenderer.render(from: parsed)
            return rendered.hasHTML || rendered.plainBody != nil ? rendered : MailContentRenderer.render(htmlBody: nil, plainBody: email.preview)
        }
        return MailContentRenderer.render(htmlBody: nil, plainBody: email.preview)
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
