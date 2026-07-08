import Foundation
import SwiftUI
#if canImport(WebKit)
import WebKit
#endif

class WebsiteScreenshotBackend: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var urlString = "https://apple.com"
    @Published var screenshot: UIImage? = nil
    @Published var isLoading = false
    @Published var error: String? = nil

    private var webView: WKWebView?

    func capture() {
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            return
        }

        isLoading = true
        error = nil
        screenshot = nil

        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1280, height: 800), configuration: config)
        webView?.navigationDelegate = self
        webView?.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait a bit for the page to fully render
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let config = WKSnapshotConfiguration()
            webView.takeSnapshot(with: config) { image, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.error = error.localizedDescription
                    } else {
                        self.screenshot = image
                    }
                    self.webView = nil
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.error = error.localizedDescription
            self.webView = nil
        }
    }
}
