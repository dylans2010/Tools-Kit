import SwiftUI

struct PlistViewerDevTool: DevTool {
    let id = "plist-viewer"
    let name = "Plist Viewer"
    let category: DevToolCategory = .data
    let icon = "list.bullet.rectangle"
    let description = "Format and inspect Property List files"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste XML Plist") { input in
            if input.contains("plist") {
                return "Plist format detected. \nKeys: \(input.components(separatedBy: "<key>").count - 1)"
            } else {
                return "Not a valid Plist XML"
            }
        }
    }
}
