import SwiftUI
import WebKit

struct MailContentRenderer: UIViewRepresentable {
    let htmlContent: String
    let plainTextContent: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Disable JavaScript for security (XSS prevention)
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false // Let SwiftUI handle scrolling
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let content = htmlContent.isEmpty ? wrapPlainText(plainTextContent) : htmlContent
        let sanitized = sanitize(content)
        uiView.loadHTMLString(sanitized, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func wrapPlainText(_ text: String) -> String {
        let escaped = text.replacingOccurrences(of: "<", with: "&lt;")
                         .replacingOccurrences(of: ">", with: "&gt;")
                         .replacingOccurrences(of: "\n", with: "<br>")
        return "<html><body style=\"font-family: -apple-system; font-size: 16px; color: #333;\">\(escaped)</body></html>"
    }

    private func sanitize(_ html: String) -> String {
        // Remove script tags and event handlers
        var sanitized = html
        let patterns = [
            "<script[\\s\\S]*?>[\\s\\S]*?<\\/script>",
            "on\\w+\\s*=\\s*\"[^\"]*\"",
            "on\\w+\\s*=\\s*'[^']*'",
            "javascript:[^\"']*"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                sanitized = regex.stringByReplacingMatches(in: sanitized, options: [], range: NSRange(location: 0, length: sanitized.utf16.count), withTemplate: "")
            }
        }
        return sanitized
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MailContentRenderer

        init(_ parent: MailContentRenderer) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
