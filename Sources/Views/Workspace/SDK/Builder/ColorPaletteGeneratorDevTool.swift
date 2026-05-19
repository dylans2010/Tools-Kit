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
        List {
            Section("Color Seed") {
                HStack(spacing: 20) {
                    ColorPicker("Primary Source", selection: $viewModel.baseColor)
                        .font(.headline)

                    Spacer()

                    Button { viewModel.baseColor = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1)) } label: {
                        Image(systemName: "die.face.5.fill")
                            .font(.title2)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Harmony Rules") {
                Picker("Algorithm", selection: $viewModel.type) {
                    Text("Mono").tag(PaletteType.monochromatic)
                    Text("Analogous").tag(PaletteType.analogous)
                    Text("Complement").tag(PaletteType.complementary)
                    Text("Triadic").tag(PaletteType.triadic)
                }
                .pickerStyle(.segmented)

                Stepper("Shades: \(viewModel.shadeCount)", value: $viewModel.shadeCount, in: 3...8)
            }

            Section("Generated Palette") {
                VStack(spacing: 12) {
                    HStack(spacing: 0) {
                        ForEach(viewModel.palette, id: \.self) { color in
                            Rectangle()
                                .fill(color)
                                .frame(height: 80)
                                .overlay(alignment: .bottom) {
                                    Text(hex(color))
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                }
                                .onTapGesture { UIPasteboard.general.string = hex(color) }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                    Text("Tap a color to copy HEX code").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Export") {
                Button {
                    UIPasteboard.general.string = viewModel.paletteCode
                } label: {
                    Label("Copy SwiftUI Array", systemImage: "doc.on.doc")
                }

                Button {
                    viewModel.sharePalette()
                } label: {
                    Label("Share Palette", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Palettes")
    }

    private func hex(_ color: Color) -> String {
        let c = color.getComponents()
        return String(format: "#%02X%02X%02X", Int(c.r*255), Int(c.g*255), Int(c.b*255))
    }
}

enum PaletteType {
    case monochromatic, analogous, complementary, triadic
}

class ColorPaletteGeneratorViewModel: ObservableObject {
    @Published var baseColor: Color = .blue
    @Published var type = PaletteType.monochromatic
    @Published var shadeCount = 5

    var palette: [Color] {
        let c = baseColor.getComponents()
        switch type {
        case .monochromatic:
            return (1...shadeCount).map { i in
                let factor = CGFloat(i) / CGFloat(shadeCount + 1)
                return Color(red: c.r * factor + (1-factor)*0.1,
                             green: c.g * factor + (1-factor)*0.1,
                             blue: c.b * factor + (1-factor)*0.1)
            }
        case .analogous:
            return [
                baseColor,
                Color(red: min(1.0, c.r * 1.2), green: c.g * 0.9, blue: c.b),
                Color(red: c.r * 0.9, green: min(1.0, c.g * 1.2), blue: c.b)
            ]
        case .complementary:
            return [
                baseColor,
                Color(red: 1.0 - c.r, green: 1.0 - c.g, blue: 1.0 - c.b),
                Color(red: (1.0 - c.r) * 0.8, green: (1.0 - c.g) * 0.8, blue: (1.0 - c.b) * 0.8)
            ]
        case .triadic:
            return [
                baseColor,
                Color(red: c.g, green: c.b, blue: c.r),
                Color(red: c.b, green: c.r, blue: c.g)
            ]
        }
    }

    var paletteCode: String {
        let colors = palette.map { c in
            let comp = c.getComponents()
            return "Color(red: \(String(format: "%.2f", comp.r)), green: \(String(format: "%.2f", comp.g)), blue: \(String(format: "%.2f", comp.b)))"
        }
        return "let palette = [\n    \(colors.joined(separator: ",\n    "))\n]"
    }

    func sharePalette() {
        let av = UIActivityViewController(activityItems: [paletteCode], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(av, animated: true)
        }
    }
}

#Preview {
    ColorPaletteGeneratorView()
}
