import SwiftUI

struct ColorPaletteGeneratorDevTool: DevTool {
    let id = "color-palette-generator"
    let name = "Color Palette Generator"
    let category = DevToolCategory.uiDesign
    let icon = "swatchpalette"
    let description = "Generate harmonious color schemes"

    func render() -> some View {
        ColorPaletteGeneratorView()
    }
}

struct ColorPaletteGeneratorView: View {
    @StateObject private var viewModel = ColorPaletteGeneratorViewModel()

    var body: some View {
        Form {
            Section("Base Color") {
                ColorPicker("Primary", selection: $viewModel.baseColor)
            }

            Section("Scheme Type") {
                Picker("Harmony", selection: $viewModel.type) {
                    Text("Monochromatic").tag(PaletteType.monochromatic)
                    Text("Analogous").tag(PaletteType.analogous)
                    Text("Complementary").tag(PaletteType.complementary)
                }
                .pickerStyle(.segmented)
            }

            Section("Generated Palette") {
                HStack(spacing: 4) {
                    ForEach(viewModel.palette, id: \.self) { color in
                        Rectangle()
                            .fill(color)
                            .frame(height: 60)
                            .overlay(Text(hex(color)).font(.caption2).foregroundStyle(.white).shadow(radius: 1))
                    }
                }
            }
        }
    }

    private func hex(_ color: Color) -> String {
        let c = color.getComponents()
        return String(format: "#%02X%02X%02X", Int(c.r*255), Int(c.g*255), Int(c.b*255))
    }
}

enum PaletteType {
    case monochromatic, analogous, complementary
}

class ColorPaletteGeneratorViewModel: ObservableObject {
    @Published var baseColor: Color = .blue
    @Published var type = PaletteType.monochromatic

    var palette: [Color] {
        let c = baseColor.getComponents()
        switch type {
        case .monochromatic:
            return [
                Color(red: c.r * 0.4, green: c.g * 0.4, blue: c.b * 0.4),
                Color(red: c.r * 0.7, green: c.g * 0.7, blue: c.b * 0.7),
                baseColor,
                Color(red: min(1.0, c.r * 1.3), green: min(1.0, c.g * 1.3), blue: min(1.0, c.b * 1.3))
            ]
        case .analogous:
            return [
                Color(red: c.r, green: c.g * 0.8, blue: c.b),
                baseColor,
                Color(red: c.r * 0.8, green: c.g, blue: c.b)
            ]
        case .complementary:
            return [
                baseColor,
                Color(red: 1.0 - c.r, green: 1.0 - c.g, blue: 1.0 - c.b)
            ]
        }
    }
}

#Preview {
    ColorPaletteGeneratorView()
}
