import SwiftUI

struct RobotsTxtGeneratorDevTool: DevTool {
    let id = "robots-txt-gen"
    let name = "Robots.txt Generator"
    let category: DevToolCategory = .networking
    let icon = "robot"
    let description = "Generate robots.txt files for website crawlers"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Allow / Disallow paths") { input in
            "User-agent: *\nDisallow: /admin/\nSitemap: https://example.com/sitemap.xml"
        }
    }
}
