import SwiftUI

struct ColorConverterDevTool: DevTool {
    let id = "color-converter"
    let name = "Color Converter"
    let category = DevToolCategory.uiDesign
    let icon = "paintpalette.fill"
    let description = "Convert colors between Hex, RGB, HSL, and CMYK"

    func render() -> some View {
        ColorConverterView()
    }
}

struct ColorConverterView: View {
    @StateObject private var viewModel = ColorConverterViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Color Converter",
                description: "Translate color values between different formats for UI development.",
                icon: "paintpalette.fill"
            )
            .padding()

            Form {
                Section("Color Selection") {
                    ColorPicker("Choose Color", selection: $viewModel.selectedColor)

                    Rectangle()
                        .fill(viewModel.selectedColor)
                        .frame(height: 60)
                        .cornerRadius(8)
                }

                Section("Formats") {
                    LabeledContent("HEX", value: viewModel.hexValue)
                    LabeledContent("RGB", value: viewModel.rgbValue)
                    LabeledContent("HSL", value: viewModel.hslValue)
                }

                Section("Code Snippets") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SwiftUI").font(.caption.bold())
                        Text(viewModel.swiftUISnippet)
                            .font(.system(.caption2, design: .monospaced))
                            .padding(4)
                            .background(Color.secondary.opacity(0.1))
                    }
                }
            }
        }
    }
}

class ColorConverterViewModel: ObservableObject {
    @Published var selectedColor: Color = .blue

    var hexValue: String {
        let components = selectedColor.getComponents()
        return String(format: "#%02X%02X%02X",
                      Int(components.r * 255),
                      Int(components.g * 255),
                      Int(components.b * 255))
    }

    var rgbValue: String {
        let components = selectedColor.getComponents()
        return "rgb(\(Int(components.r * 255)), \(Int(components.g * 255)), \(Int(components.b * 255)))"
    }

    var hslValue: String {
        let components = selectedColor.getComponents()
        let r = Double(components.r)
        let g = Double(components.g)
        let b = Double(components.b)

        let minV = min(r, min(g, b))
        let maxV = max(r, max(g, b))
        let delta = maxV - minV

        var h: Double = 0
        var s: Double = 0
        let l = (maxV + minV) / 2

        if delta != 0 {
            s = l < 0.5 ? delta / (maxV + minV) : delta / (2 - maxV - minV)

            if r == maxV {
                h = (g - b) / delta + (g < b ? 6 : 0)
            } else if g == maxV {
                h = (b - r) / delta + 2
            } else {
                h = (r - g) / delta + 4
            }
            h /= 6
        }

        return "hsl(\(Int(h * 360)), \(Int(s * 100))%, \(Int(l * 100))%)"
    }

    var swiftUISnippet: String {
        "Color(red: \(String(format: "%.2f", selectedColor.getComponents().r)), green: \(String(format: "%.2f", selectedColor.getComponents().g)), blue: \(String(format: "%.2f", selectedColor.getComponents().b)))"
    }
}
