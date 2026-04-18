import SwiftUI
import WebKit

struct EmailDetailView: View {
    @ObservedObject var viewModel: MailViewModel
    let email: EmailMessage
    var account: MailAccount? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var bodyWebViewHeight: CGFloat = 320
    @State private var showReplyComposer = false
    @State private var summary = ""
    @State private var isSummarizing = false
    @State private var actionError: String?

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
                        Text(summary)
                            .font(.subheadline)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    }

                    contentView(minHeight: max(geo.size.height * 0.78, 420))

                    if let actionError {
                        Text(actionError)
                            .font(.footnote)
                            .foregroundStyle(.red)
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
                            archiveEmail()
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }

                        Button(role: .destructive) {
                            deleteEmail()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showReplyComposer) {
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
                    Text(plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: minHeight, alignment: .topLeading)
                }
            } else {
                ProgressView("Loading Body...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            }
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

    private func deleteEmail() {
        if let idx = viewModel.emails.firstIndex(where: { $0.uid == email.uid }) {
            viewModel.emails.remove(at: idx)
        }
        dismiss()
    }

    private func archiveEmail() {
        if let idx = viewModel.emails.firstIndex(where: { $0.uid == email.uid }) {
            viewModel.emails[idx].isRead = true
        }
        dismiss()
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
}
