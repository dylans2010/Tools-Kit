import SwiftUI

struct ColorPaletteGeneratorTool: DevTool {
    let id = UUID()
    let name = "Color Palette Generator"
    let category: DevToolCategory = .uiDesign
    let icon = "swatchpalette"
    let description = "Generate harmonious color palettes"
    func render() -> some View { ColorPaletteGeneratorDevToolView() }
}

struct ColorPaletteGeneratorDevToolView: View {
    @State private var baseHue: Double = 0.5
    @State private var saturation: Double = 0.7
    @State private var brightness: Double = 0.9
    @State private var mode = 0

    private let modes = ["Complementary", "Analogous", "Triadic", "Split-Complementary", "Monochromatic"]

    private var palette: [Color] {
        switch mode {
        case 0: return [Color(hue: baseHue, saturation: saturation, brightness: brightness),
                        Color(hue: (baseHue + 0.5).truncatingRemainder(dividingBy: 1), saturation: saturation, brightness: brightness)]
        case 1: return (0..<5).map { Color(hue: (baseHue + Double($0) * 0.05 - 0.1).truncatingRemainder(dividingBy: 1), saturation: saturation, brightness: brightness) }
        case 2: return [0, 0.333, 0.666].map { Color(hue: (baseHue + $0).truncatingRemainder(dividingBy: 1), saturation: saturation, brightness: brightness) }
        case 3: return [0, 0.4167, 0.5833].map { Color(hue: (baseHue + $0).truncatingRemainder(dividingBy: 1), saturation: saturation, brightness: brightness) }
        case 4: return (0..<5).map { Color(hue: baseHue, saturation: saturation, brightness: max(0.2, brightness - Double($0) * 0.15)) }
        default: return []
        }
    }

    var body: some View {
        Form {
            Section("Base Color") {
                RoundedRectangle(cornerRadius: 8).fill(Color(hue: baseHue, saturation: saturation, brightness: brightness)).frame(height: 50)
                LabeledContent("Hue") { Slider(value: $baseHue) }
                LabeledContent("Saturation") { Slider(value: $saturation) }
                LabeledContent("Brightness") { Slider(value: $brightness) }
            }
            Section("Mode") {
                Picker("Harmony", selection: $mode) {
                    ForEach(0..<modes.count, id: \.self) { Text(modes[$0]) }
                }
                .pickerStyle(.segmented)
            }
            Section("Palette") {
                HStack(spacing: 4) {
                    ForEach(0..<palette.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(palette[i])
                            .frame(height: 60)
                    }
                }
            }
        }
        .navigationTitle("Color Palette Generator")
    }
}
