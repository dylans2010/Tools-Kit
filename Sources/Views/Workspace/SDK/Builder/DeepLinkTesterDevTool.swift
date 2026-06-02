import SwiftUI

struct DeepLinkTesterDevTool: DevTool {
    let id = "deep-link-tester"
    let name = "Deep Link Tester"
    let category: DevToolCategory = .automation
    let icon = "link"
    let description = "Test app's custom URL schemes and universal links"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter Deep Link URL") { input in
            guard let url = URL(string: input) else { return "Invalid URL" }
            return "Opening: \(url.absoluteString)\nCheck 'scene(_:openURLContexts:)' in your AppDelegate/SceneDelegate."
        }
    }
}
