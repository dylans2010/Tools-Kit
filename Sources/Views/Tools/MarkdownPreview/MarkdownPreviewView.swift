import SwiftUI
import WebKit

struct MarkdownPreviewView: View {
    @StateObject private var backend = MarkdownPreviewBackend()
    @State private var markdown: String = "# Hello World"

    var body: some View {
        ToolDetailView(tool: MarkdownPreviewTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Markdown Input") {
                    TextEditor(text: $markdown)
                        .frame(height: 200)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .onChange(of: markdown) { _, _ in backend.renderMarkdown(markdown) }
                }

                ToolInputSection("Preview") {
                    HTMLView(html: backend.html)
                        .frame(height: 300)
                        .cornerRadius(12)
                }
            }
        }
        .onAppear { backend.renderMarkdown(markdown) }
    }
}

struct HTMLView: UIViewRepresentable {
    let html: String
    func makeUIView(context: Context) -> WKWebView { WKWebView() }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

struct MarkdownPreviewTool: Tool, Sendable {
    let name = "Markdown Preview"
    let icon = "text.justify.left"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Real-time preview for Markdown documents"
    let requiresAPI = false
    var view: AnyView { AnyView(MarkdownPreviewView()) }
}
