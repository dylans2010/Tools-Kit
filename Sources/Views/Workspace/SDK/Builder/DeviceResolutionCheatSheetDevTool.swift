import SwiftUI

struct DeviceResolutionCheatSheetDevTool: DevTool {
    let id = "device-resolutions"
    let name = "Device Resolution Cheat Sheet"
    let category: DevToolCategory = .uiDesign
    let icon = "iphone"
    let description = "Resolutions and screen sizes for Apple devices"

    func render() -> some View {
        List {
            Text("iPhone 15 Pro Max: 430 x 932 pt (3x)")
            Text("iPhone 15 Pro: 393 x 852 pt (3x)")
            Text("iPhone 14 Plus: 428 x 926 pt (3x)")
            Text("iPhone 14: 390 x 844 pt (3x)")
            Text("iPhone 13 mini: 375 x 812 pt (3x)")
            Text("iPhone SE (3rd gen): 375 x 667 pt (2x)")
        }
    }
}
