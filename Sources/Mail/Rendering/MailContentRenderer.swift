import SwiftUI
import WebKit

struct MailContentRenderer: UIViewRepresentable {
    let htmlContent: String
    let plainTextContent: String

    // MARK: - Convenience factory methods

    /// Create a renderer that displays an HTML email.
    static func renderHTML(_ html: String) -> MailContentRenderer {
        MailContentRenderer(htmlContent: html, plainTextContent: "")
    }

    /// Create a renderer that displays a plain-text email.
    static func renderPlainText(_ text: String) -> MailContentRenderer {
        MailContentRenderer(htmlContent: "", plainTextContent: text)
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Disable JavaScript for security (XSS prevention)
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false // Let SwiftUI handle scrolling
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlString: String
        if htmlContent.isEmpty {
            htmlString = wrapPlainText(plainTextContent)
        } else {
            htmlString = injectCSS(sanitize(htmlContent))
        }
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - CSS injection

    private var emailCSS: String {
        """
        <style>
          :root {
            color-scheme: light dark;
          }
          * {
            box-sizing: border-box;
            -webkit-text-size-adjust: 100%;
          }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 16px;
            line-height: 1.6;
            margin: 0;
            padding: 12px 16px;
            word-break: break-word;
            overflow-wrap: break-word;
            color: #1c1c1e;
            background-color: transparent;
          }
          @media (prefers-color-scheme: dark) {
            body { color: #e5e5ea; }
            a    { color: #64d2ff; }
          }
          img   { max-width: 100%; height: auto; display: block; }
          table { max-width: 100%; border-collapse: collapse; }
          pre, code {
            font-family: 'Menlo', monospace;
            font-size: 13px;
            background: rgba(0,0,0,0.05);
            border-radius: 4px;
            padding: 2px 4px;
            overflow-x: auto;
          }
          @media (prefers-color-scheme: dark) {
            pre, code { background: rgba(255,255,255,0.08); }
          }
          blockquote {
            border-left: 3px solid #c7c7cc;
            margin: 8px 0;
            padding: 0 12px;
            color: #636366;
          }
          @media (prefers-color-scheme: dark) {
            blockquote { border-color: #48484a; color: #8e8e93; }
          }
          a { color: #007aff; text-decoration: none; }
        </style>
        """
    }

    private func injectCSS(_ html: String) -> String {
        // Insert CSS into existing <head> if present, otherwise wrap the whole thing
        if let headRange = html.range(of: "</head>", options: .caseInsensitive) {
            return html.replacingCharacters(in: headRange, with: emailCSS + "</head>")
        } else if let htmlRange = html.range(of: "<html", options: .caseInsensitive) {
            // Has <html> tag but no <head> — insert after <html ...>
            if let endOfTag = html.range(of: ">", range: htmlRange.upperBound..<html.endIndex) {
                return html.replacingCharacters(
                    in: endOfTag,
                    with: "><head>" + emailCSS + "</head>"
                )
            }
        }
        // Plain HTML fragment — wrap in a full document
        return "<html><head>\(emailCSS)</head><body>\(html)</body></html>"
    }

    private func wrapPlainText(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
        return "<html><head>\(emailCSS)</head><body><pre style='white-space:pre-wrap;font-family:inherit'>\(escaped)</pre></body></html>"
    }

    private func sanitize(_ html: String) -> String {
        var sanitized = html
        let patterns = [
            "<script[\\s\\S]*?>[\\s\\S]*?<\\/script>",
            "on\\w+\\s*=\\s*\"[^\"]*\"",
            "on\\w+\\s*=\\s*'[^']*'",
            "javascript:[^\"']*"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                sanitized = regex.stringByReplacingMatches(
                    in: sanitized,
                    options: [],
                    range: NSRange(location: 0, length: sanitized.utf16.count),
                    withTemplate: ""
                )
            }
        }
        return sanitized
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MailContentRenderer

        init(_ parent: MailContentRenderer) {
            self.parent = parent
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
