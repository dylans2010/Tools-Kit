import SwiftUI
import WebKit

struct EmailDetailView: View {
    @ObservedObject var viewModel: MailViewModel
    let email: EmailMessage
    @State private var bodyWebViewHeight: CGFloat = 320

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
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)

                contentView
            }
            .padding(.top, 10)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if resolvedEmail.body == nil && resolvedEmail.htmlBody == nil {
                viewModel.loadBody(for: email)
            }
        }
    }

    private var contentView: some View {
        Group {
            if let content = renderContent(from: resolvedEmail) {
                if content.hasHTML, let html = content.htmlBody {
                    MailWebView(htmlString: html, dynamicHeight: $bodyWebViewHeight)
                        .frame(height: bodyWebViewHeight)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal)
                } else if let plain = content.plainBody {
                    Text(plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )
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
                .padding(.top, 20)
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

        return MailContentRenderer.render(htmlBody: nil, plainBody: message.preview)
    }
}
