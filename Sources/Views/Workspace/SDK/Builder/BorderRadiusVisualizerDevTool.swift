import SwiftUI

struct BorderRadiusVisualizerDevTool: DevTool {
    let id = "border-radius-viz"
    let name = "Border Radius Visualizer"
    let category: DevToolCategory = .uiDesign
    let icon = "square.dashed"
    let description = "Visualize different corner radii in SwiftUI"

    @State private var radius: CGFloat = 10

    func render() -> some View {
        VStack {
            Slider(value: $radius, in: 0...100)
            Text("Radius: \(Int(radius))")
            RoundedRectangle(cornerRadius: radius)
                .fill(.blue)
                .frame(width: 150, height: 150)
            Text(".cornerRadius(\(Int(radius)))")
        }.padding()
    }
}
