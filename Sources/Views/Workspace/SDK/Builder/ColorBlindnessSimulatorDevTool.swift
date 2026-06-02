import SwiftUI

struct ColorBlindnessSimulatorDevTool: DevTool {
    let id = "color-blind-sim"
    let name = "Color Blindness Simulator"
    let category: DevToolCategory = .uiDesign
    let icon = "eye.trianglebadge.exclamationmark"
    let description = "Simulate how colors appear to color-blind users"

    func render() -> some View {
        VStack {
            ColorPicker("Pick a color", selection: .constant(.blue))
            Divider()
            Text("Protanopia (Red-blind)")
            Text("Deuteranopia (Green-blind)")
            Text("Tritanopia (Blue-blind)")
        }.padding()
    }
}
