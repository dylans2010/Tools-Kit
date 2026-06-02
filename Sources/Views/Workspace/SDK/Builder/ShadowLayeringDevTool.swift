import SwiftUI

struct ShadowLayeringDevTool: DevTool {
    let id = "shadow-layering"
    let name = "Shadow Layering Tool"
    let category: DevToolCategory = .uiDesign
    let icon = "square.stack.3d.down.right"
    let description = "Layer multiple shadows for realistic depth effects"

    func render() -> some View {
        ShadowLayeringView()
    }
}

struct ShadowLayeringView: View {
    @State private var radius: Double = 10
    @State private var opacity: Double = 0.2

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .frame(width: 150, height: 150)
                .shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: radius/2)
                .shadow(color: .black.opacity(opacity * 0.5), radius: radius * 2, x: 0, y: radius)
                .padding(50)

            Form {
                HStack {
                    Text("Base Radius")
                    Slider(value: $radius, in: 0...50)
                }
                HStack {
                    Text("Opacity")
                    Slider(value: $opacity, in: 0...1)
                }
            }
        }
    }
}
