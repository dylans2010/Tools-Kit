import SwiftUI

struct EntitlementsGeneratorDevTool: DevTool {
    let id = "entitlements-gen"
    let name = "Entitlements Generator"
    let category: DevToolCategory = .security
    let icon = "checklist"
    let description = "Generate app entitlements plist template"

    func render() -> some View {
        Text(".entitlements XML Template")
            .font(.headline)
            .padding()
        Text("<plist version=\"1.0\">\n<dict>\n  <key>com.apple.security.app-sandbox</key>\n  <true/>\n  <key>com.apple.developer.networking.wifi-info</key>\n  <true/>\n</dict>\n</plist>")
            .font(.system(.caption, design: .monospaced))
            .padding()
    }
}
