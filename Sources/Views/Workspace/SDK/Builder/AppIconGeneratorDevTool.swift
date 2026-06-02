import SwiftUI

struct AppIconGeneratorDevTool: DevTool {
    let id = "app-icon-gen"
    let name = "App Icon Generator"
    let category: DevToolCategory = .uiDesign
    let icon = "app.square"
    let description = "Generate required app icon sizes from an image"

    func render() -> some View {
        List {
            Section("iOS Icon Sizes") {
                Text("iPhone App: 60x60 (2x, 3x)")
                Text("iPad App: 76x76 (2x)")
                Text("iPad Pro App: 83.5x83.5 (2x)")
                Text("App Store: 1024x1024 (1x)")
            }
            Section("macOS Icon Sizes") {
                Text("16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024")
            }
        }
    }
}
