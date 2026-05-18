import SwiftUI

struct GradientBuilderTool: DevTool {
    let id = UUID()
    let name = "Gradient Builder"
    let category: DevToolCategory = .uiDesign
    let icon = "square.fill.on.square.fill"
    let description = "Build and preview linear gradients"
    func render() -> some View { GradientBuilderDevToolView() }
}

struct GradientBuilderDevToolView: View {
    @State private var startHue: Double = 0.0
    @State private var endHue: Double = 0.6
    @State private var angle: Double = 0

    private var startColor: Color { Color(hue: startHue, saturation: 0.8, brightness: 0.9) }
    private var endColor: Color { Color(hue: endHue, saturation: 0.8, brightness: 0.9) }

    var body: some View {
        Form {
            Section("Preview") {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [startColor, endColor],
                                         startPoint: gradientStart, endPoint: gradientEnd))
                    .frame(height: 150)
            }
            Section("Start Color") {
                LabeledContent("Hue") { Slider(value: $startHue) }
                RoundedRectangle(cornerRadius: 4).fill(startColor).frame(height: 30)
            }
            Section("End Color") {
                LabeledContent("Hue") { Slider(value: $endHue) }
                RoundedRectangle(cornerRadius: 4).fill(endColor).frame(height: 30)
            }
            Section("Direction") {
                LabeledContent("Angle: \(Int(angle))°") { Slider(value: $angle, in: 0...360) }
            }
            Section("Code") {
                Text("LinearGradient(colors: [.init(hue: \(String(format: "%.2f", startHue)), saturation: 0.8, brightness: 0.9), .init(hue: \(String(format: "%.2f", endHue)), saturation: 0.8, brightness: 0.9)], startPoint: .leading, endPoint: .trailing)")
                    .font(.system(.caption2, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Gradient Builder")
    }

    private var gradientStart: UnitPoint {
        let rad = angle * .pi / 180
        return UnitPoint(x: 0.5 - cos(rad) * 0.5, y: 0.5 - sin(rad) * 0.5)
    }
    private var gradientEnd: UnitPoint {
        let rad = angle * .pi / 180
        return UnitPoint(x: 0.5 + cos(rad) * 0.5, y: 0.5 + sin(rad) * 0.5)
    }
}
