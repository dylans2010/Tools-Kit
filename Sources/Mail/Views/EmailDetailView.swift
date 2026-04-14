import SwiftUI
import WebKit

struct EmailDetailView: View {
    @ObservedObject var viewModel: MailViewModel
    let email: EmailMessage
    @State private var renderedContent: RenderedMailContent?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(email.subject)
                        .font(.title2)
                        .bold()
                    Text(email.sender)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Divider()

                contentView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contentView: some View {
        Group {
            if let content = renderedContent ?? renderContent(from: resolvedEmail) {
                if content.hasHTML, let html = content.htmlBody {
                    MailWebView(htmlString: html)
                        .frame(minHeight: 400)
                        .padding(.horizontal, 4)
                } else if let plain = content.plainBody {
                    Text(plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
            } else {
                HStack {
                    Spacer()
                    VStack {
                        ProgressView()
                        Text("Loading Body...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .onAppear {
                    viewModel.loadBody(for: email)
                    renderedContent = renderContent(from: resolvedEmail)
                }
            }
        }
    }

    private var resolvedEmail: EmailMessage {
        viewModel.emails.first(where: { $0.uid == email.uid }) ?? email
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

        return nil
    }
}
