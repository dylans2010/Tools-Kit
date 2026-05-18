import SwiftUI

struct ColorMixerTool: DevTool {
    let id = UUID()
    let name = "Color Mixer"
    let category: DevToolCategory = .uiDesign
    let icon = "drop.fill"
    let description = "Mix two colors with adjustable ratio"
    func render() -> some View { ColorMixerDevToolView() }
}

struct ColorMixerDevToolView: View {
    @State private var hue1: Double = 0.0
    @State private var hue2: Double = 0.6
    @State private var ratio: Double = 0.5

    private var color1: Color { Color(hue: hue1, saturation: 0.8, brightness: 0.9) }
    private var color2: Color { Color(hue: hue2, saturation: 0.8, brightness: 0.9) }
    private var mixed: Color {
        let h = hue1 * (1 - ratio) + hue2 * ratio
        return Color(hue: h, saturation: 0.8, brightness: 0.9)
    }

    var body: some View {
        Form {
            Section("Color 1") {
                RoundedRectangle(cornerRadius: 8).fill(color1).frame(height: 40)
                LabeledContent("Hue") { Slider(value: $hue1) }
            }
            Section("Color 2") {
                RoundedRectangle(cornerRadius: 8).fill(color2).frame(height: 40)
                LabeledContent("Hue") { Slider(value: $hue2) }
            }
            Section("Mix Ratio") {
                LabeledContent("\(Int(ratio * 100))%") { Slider(value: $ratio) }
            }
            Section("Result") {
                RoundedRectangle(cornerRadius: 12).fill(mixed).frame(height: 80)
            }
        }
        .navigationTitle("Color Mixer")
    }
}
