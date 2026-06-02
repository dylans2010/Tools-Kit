import SwiftUI

struct PrivacyManifestGeneratorDevTool: DevTool {
    let id = "privacy-manifest-gen"
    let name = "Privacy Manifest Generator"
    let category: DevToolCategory = .security
    let icon = "hand.raised.fill"
    let description = "Generate PrivacyInfo.xcprivacy file template"

    func render() -> some View {
        Text("PrivacyInfo.xcprivacy XML Template")
            .font(.headline)
            .padding()
        Text("<plist version=\"1.0\">\n<dict>\n  <key>NSPrivacyTracking</key>\n  <false/>\n  <key>NSPrivacyAccessedAPITypes</key>\n  <array/>\n</dict>\n</plist>")
            .font(.system(.caption, design: .monospaced))
            .padding()
    }
}
