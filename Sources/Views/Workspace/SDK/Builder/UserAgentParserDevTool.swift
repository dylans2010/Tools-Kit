import SwiftUI

struct UserAgentParserDevTool: DevTool {
    let id = "ua-parser"
    let name = "User Agent Parser"
    let category: DevToolCategory = .networking
    let icon = "person.text.rectangle"
    let description = "Extract browser and OS info from User-Agent strings"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Mozilla/5.0...") { input in
            if input.contains("iPhone") { return "Device: iPhone\nOS: iOS\nBrowser: Mobile Safari" }
            if input.contains("Macintosh") { return "Device: Mac\nOS: macOS\nBrowser: Safari/Chrome" }
            return "Generic Browser / OS"
        }
    }
}
