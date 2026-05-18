import SwiftUI

struct ColorConverterDevTool: DevTool {
    let id = "color-converter"
    let name = "Color Converter"
    let category = DevToolCategory.uiDesign
    let icon = "drop.fill"
    let description = "Convert between Hex, RGB, and HSL"

    func render() -> some View {
        ColorConverterView()
    }
}

struct ColorConverterView: View {
    @StateObject private var viewModel = ColorConverterViewModel()

    var body: some View {
        Form {
            Section("Color Picker") {
                ColorPicker("Select Color", selection: $viewModel.color)
            }

            Section("Formats") {
                LabeledContent("Hex", value: viewModel.hexString)
                LabeledContent("RGB", value: viewModel.rgbString)
                LabeledContent("HSL", value: viewModel.hslString)
            }

            Section("Preview") {
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.color)
                    .frame(height: 100)
            }
        }
    }
}

class ColorConverterViewModel: ObservableObject {
    @Published var color: Color = .blue

    var hexString: String {
        let components = color.getComponents()
        return String(format: "#%02X%02X%02X",
                      Int(components.r * 255),
                      Int(components.g * 255),
                      Int(components.b * 255))
    }

    var rgbString: String {
        let components = color.getComponents()
        return "rgb(\(Int(components.r * 255)), \(Int(components.g * 255)), \(Int(components.b * 255)))"
    }

    var hslString: String {
        let uiColor = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, l: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &l, alpha: &a)
        return "hsl(\(Int(h * 360))°, \(Int(s * 100))%, \(Int(l * 100))%)"
    }
}
