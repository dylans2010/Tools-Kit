import SwiftUI

struct MeshGradientBuilderDevTool: DevTool {
    let id = "mesh-gradient-builder"
    let name = "Mesh Gradient Builder"
    let category: DevToolCategory = .uiDesign
    let icon = "square.stack.3d.up.fill"
    let description = "Interactive builder for complex mesh-style gradients"

    func render() -> some View {
        MeshGradientBuilderView()
    }
}

struct MeshGradientBuilderView: View {
    @State private var color1 = Color.blue
    @State private var color2 = Color.purple
    @State private var color3 = Color.pink
    @State private var color4 = Color.orange

    var body: some View {
        VStack {
            ZStack {
                LinearGradient(colors: [color1, color2, color3, color4], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .blur(radius: 50)
            }
            .frame(height: 300)
            .cornerRadius(12)
            .padding()

            Form {
                ColorPicker("Color 1", selection: $color1)
                ColorPicker("Color 2", selection: $color2)
                ColorPicker("Color 3", selection: $color3)
                ColorPicker("Color 4", selection: $color4)
            }
        }
    }
}
