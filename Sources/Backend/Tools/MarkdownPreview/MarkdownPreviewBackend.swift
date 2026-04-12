import Foundation

final class MarkdownPreviewBackend: ObservableObject {
    @Published var html: String = ""

    func renderMarkdown(_ markdown: String) {
        // Simplified: In a real app, use a Markdown library
        // Here we just wrap in some basic HTML
        self.html = "<html><body>" + markdown.replacingOccurrences(of: "\n", with: "<br>") + "</body></html>"
    }
}
