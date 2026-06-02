import SwiftUI

struct ColorBlendingDevTool: DevTool {
    let id = "color-blending"
    let name = "Color Blending Tool"
    let category: DevToolCategory = .uiDesign
    let icon = "drop.fill"
    let description = "Blend colors using different mathematical models"

    func render() -> some View {
        ColorBlendingView()
    }
}

struct ColorBlendingView: View {
    @State private var color1 = Color.red
    @State private var color2 = Color.blue
    @State private var ratio = 0.5

    var body: some View {
        Form {
            ColorPicker("Color 1", selection: $color1)
            ColorPicker("Color 2", selection: $color2)
            HStack {
                Text("Ratio")
                Slider(value: $ratio, in: 0...1)
            }

            Section("Blended Result") {
                Rectangle()
                    .fill(blend(color1, color2, ratio: ratio))
                    .frame(height: 100)
                    .cornerRadius(8)
            }
        }
    }

    private func blend(_ c1: Color, _ c2: Color, ratio: Double) -> Color {
        let uiColor1 = UIColor(c1)
        let uiColor2 = UIColor(c2)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return Color(red: Double(r1 * CGFloat(1 - ratio) + r2 * CGFloat(ratio)),
                     green: Double(g1 * CGFloat(1 - ratio) + g2 * CGFloat(ratio)),
                     blue: Double(b1 * CGFloat(1 - ratio) + b2 * CGFloat(ratio)))
    }
}
