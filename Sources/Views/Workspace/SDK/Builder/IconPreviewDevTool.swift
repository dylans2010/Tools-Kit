import SwiftUI

struct IconPreviewDevTool: DevTool {
    let id = "icon-preview"
    let name = "Icon Preview"
    let category: DevToolCategory = .uiDesign
    let icon = "app.badge"
    let description = "Preview app icons at all required sizes"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter SF Symbol name") { "Icon: \($0)\nSizes: 16x16, 20x20, 29x29, 32x32, 40x40, 58x58, 60x60, 76x76, 80x80, 87x87, 120x120, 152x152, 167x167, 180x180, 1024x1024" } }
}
