import SwiftUI
import WebKit

struct RenderedMailContent {
    let htmlBody: String?
    let plainBody: String?
    let hasHTML: Bool
}

enum MailContentRenderer {
    static func render(htmlBody: String?, plainBody: String?) -> RenderedMailContent {
        let sanitizedHTML = htmlBody?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            .map { sanitizeHTML($0) }
            .map { wrapHTMLDocument($0) }

        let cleanedPlain = plainBody?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        if let sanitizedHTML {
            return RenderedMailContent(htmlBody: sanitizedHTML, plainBody: cleanedPlain, hasHTML: true)
        }

        if let cleanedPlain {
            return RenderedMailContent(htmlBody: nil, plainBody: cleanedPlain, hasHTML: false)
        }

        return RenderedMailContent(htmlBody: nil, plainBody: nil, hasHTML: false)
    }

    static func render(from parsed: ParsedMIMEMessage) -> RenderedMailContent {
        let html = parsed.htmlPart.flatMap { MailContentDecoder.decode(data: $0.data, charset: $0.charset) }
        let plain = parsed.textPart.flatMap { MailContentDecoder.decode(data: $0.data, charset: $0.charset) }
        return render(htmlBody: html, plainBody: plain)
    }

    // MARK: - Sanitisation & Wrapping

    private static func sanitizeHTML(_ html: String) -> String {
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

    private static func wrapPlainTextHTML(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
        return "<html><head>\(emailCSS)</head><body><pre style='white-space:pre-wrap;font-family:inherit'>\(escaped)</pre></body></html>"
    }

    private static func wrapHTMLDocument(_ html: String) -> String {
        if let headRange = html.range(of: "</head>", options: .caseInsensitive) {
            return html.replacingCharacters(in: headRange, with: emailCSS + "</head>")
        } else if let htmlRange = html.range(of: "<html", options: .caseInsensitive) {
            if let endOfTag = html.range(of: ">", range: htmlRange.upperBound..<html.endIndex) {
                return html.replacingCharacters(in: endOfTag, with: "><head>" + emailCSS + "</head>")
            }
        }
        return "<html><head>\(emailCSS)</head><body>\(html)</body></html>"
    }

    private static var emailCSS: String {
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
}

#if os(iOS)
typealias NativeView = UIView
typealias NativeViewRepresentable = UIViewRepresentable
#elseif os(macOS)
typealias NativeView = NSView
typealias NativeViewRepresentable = NSViewRepresentable
#endif

struct MailWebView: NativeViewRepresentable {
    let htmlString: String
    @Binding var dynamicHeight: CGFloat

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        let webView = createWebView(context: context)
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        updateWebView(uiView, context: context)
    }
    #elseif os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        return createWebView(context: context)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        updateWebView(nsView, context: context)
    }
    #endif

    private func createWebView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        #if os(iOS)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        #endif
        return webView
    }

    private func updateWebView(_ webView: WKWebView, context: Context) {
        context.coordinator.onHeightChange = { height in
            DispatchQueue.main.async {
                dynamicHeight = max(320, height)
            }
        }

        guard context.coordinator.loadedHTML != htmlString else { return }
        context.coordinator.loadedHTML = htmlString
        webView.loadHTMLString(htmlString, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var loadedHTML: String?
        var onHeightChange: ((CGFloat) -> Void)?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                #if os(iOS)
                UIApplication.shared.open(url)
                #elseif os(macOS)
                NSWorkspace.shared.open(url)
                #endif
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)") { result, _ in
                let height: CGFloat
                if let number = result as? NSNumber {
                    height = CGFloat(truncating: number)
                } else if let doubleValue = result as? Double {
                    height = CGFloat(doubleValue)
                } else {
                    height = 320
                }
                self.onHeightChange?(height)
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
