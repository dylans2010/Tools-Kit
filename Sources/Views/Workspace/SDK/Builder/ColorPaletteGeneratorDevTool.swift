import SwiftUI

struct ColorPaletteGeneratorDevTool: DevTool {
    let id = "color-palette-generator"
    let name = "Color Palette Generator"
    let category = DevToolCategory.uiDesign
    let icon = "swatchpalette"
    let description = "Generate color schemes"

    func render() -> some View {
        ColorPaletteGeneratorView()
    }
}

struct ColorPaletteGeneratorView: View {
    @StateObject private var viewModel = ColorPaletteGeneratorViewModel()

    var body: some View {
        Form {
            Section("Base Color") {
                ColorPicker("Select Color", selection: $viewModel.baseColor)
            }

            Section("Monochromatic") {
                HStack(spacing: 0) {
                    ForEach(viewModel.monochromatic, id: \.self) { color in
                        Rectangle()
                            .fill(color)
                            .frame(height: 50)
                    }
                }
            }

            Section("Analogous") {
                HStack(spacing: 0) {
                    ForEach(viewModel.analogous, id: \.self) { color in
                        Rectangle()
                            .fill(color)
                            .frame(height: 50)
                    }
                }
            }

            Button("Generate New Palette") {
                viewModel.generate()
            }
        }
    }
}

class ColorPaletteGeneratorViewModel: ObservableObject {
    @Published var baseColor: Color = .blue {
        didSet { generate() }
    }
    @Published var monochromatic: [Color] = []
    @Published var analogous: [Color] = []

    init() {
        generate()
    }

    func generate() {
        let uiColor = UIColor(baseColor)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        monochromatic = [
            Color(hue: Double(h), saturation: Double(s), brightness: Double(max(0, b - 0.4))),
            Color(hue: Double(h), saturation: Double(s), brightness: Double(max(0, b - 0.2))),
            baseColor,
            Color(hue: Double(h), saturation: Double(max(0, s - 0.2)), brightness: Double(b)),
            Color(hue: Double(h), saturation: Double(max(0, s - 0.4)), brightness: Double(b))
        ]

        analogous = [
            Color(hue: Double((h + 0.08).truncatingRemainder(dividingBy: 1.0)), saturation: Double(s), brightness: Double(b)),
            baseColor,
            Color(hue: Double((h - 0.08 + 1.0).truncatingRemainder(dividingBy: 1.0)), saturation: Double(s), brightness: Double(b))
        ]
    }
}
