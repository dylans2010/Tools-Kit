import SwiftUI

struct ColorHarmonyGeneratorDevTool: DevTool {
    let id = "color-harmony"
    let name = "Color Harmony Generator"
    let category: DevToolCategory = .uiDesign
    let icon = "circle.grid.cross"
    let description = "Generate complementary and triadic color schemes"

    func render() -> some View {
        VStack {
            ColorPicker("Base Color", selection: .constant(.blue))
            HStack {
                Rectangle().fill(.blue).frame(height: 50)
                Rectangle().fill(.orange).frame(height: 50)
            }
            Text("Complementary Colors")
        }.padding()
    }
}
