import SwiftUI

struct SitemapGeneratorDevTool: DevTool {
    let id = "sitemap-gen"
    let name = "Sitemap Generator"
    let category: DevToolCategory = .networking
    let icon = "map"
    let description = "Generate XML sitemaps for SEO"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "https://example.com/page1") { input in
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n  <url>\n    <loc>\(input)</loc>\n    <lastmod>2024-05-20</lastmod>\n  </url>\n</urlset>"
        }
    }
}
