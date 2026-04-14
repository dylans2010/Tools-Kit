import SwiftUI
import WebKit

struct EmailDetailView: View {
    @ObservedObject var viewModel: MailViewModel
    let email: EmailMessage

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

                if let body = email.body {
                    if body.contains("<html") || body.contains("<body") || body.starts(with: "<") {
                        MailHTMLRenderer(html: body)
                            .frame(minHeight: 400)
                    } else {
                        Text(cleanBody(body))
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
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cleanBody(_ body: String) -> String {
        // Strip IMAP fetch artifacts ({123}, etc.)
        let pattern = #"^\{\d+\}\r\n"#
        return body.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
}

struct MailHTMLRenderer: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}
