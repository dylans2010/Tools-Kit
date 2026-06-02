import SwiftUI

struct AppStoreSizesCheatSheetDevTool: DevTool {
    let id = "app-store-sizes"
    let name = "App Store Sizes Cheat Sheet"
    let category: DevToolCategory = .uiDesign
    let icon = "info.circle"
    let description = "Cheat sheet for App Store screenshot and icon sizes"

    func render() -> some View {
        List {
            Section("iPhone Screenshots") {
                Text("6.7\" (iPhone 15 Pro Max): 1290 x 2796 px")
                Text("6.5\" (iPhone 11 Pro Max): 1242 x 2688 px")
                Text("5.5\" (iPhone 8 Plus): 1242 x 2208 px")
            }
            Section("iPad Screenshots") {
                Text("12.9\" (iPad Pro): 2048 x 2732 px")
            }
            Section("App Icon") {
                Text("1024 x 1024 px (PNG, no transparency)")
            }
        }
    }
}
