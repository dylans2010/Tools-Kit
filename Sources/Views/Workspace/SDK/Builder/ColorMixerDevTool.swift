import SwiftUI

struct ColorMixerDevTool: DevTool {
    let id = "color-mixer"
    let name = "Color Mixer"
    let category = DevToolCategory.uiDesign
    let icon = "paintbrush.pointed.fill"
    let description = "Mix two colors together"

    func render() -> some View {
        ColorMixerView()
    }
}

struct ColorMixerView: View {
    @StateObject private var viewModel = ColorMixerViewModel()

    var body: some View {
        Form {
            Section("Source Colors") {
                ColorPicker("Color A", selection: $viewModel.colorA)
                ColorPicker("Color B", selection: $viewModel.colorB)
            }

            Section("Mix Ratio") {
                Slider(value: $viewModel.ratio, in: 0...1)
                Text("\(Int(viewModel.ratio * 100))% Color B")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Result") {
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.mixedColor)
                    .frame(height: 100)

                LabeledContent("Result Hex", value: viewModel.mixedHex)
            }
        }
    }
}

class ColorMixerViewModel: ObservableObject {
    @Published var colorA: Color = .red
    @Published var colorB: Color = .blue
    @Published var ratio: Double = 0.5

    var mixedColor: Color {
        let c1 = colorA.getComponents()
        let c2 = colorB.getComponents()
        let r = Double(c1.r) * (1 - ratio) + Double(c2.r) * ratio
        let g = Double(c1.g) * (1 - ratio) + Double(c2.g) * ratio
        let b = Double(c1.b) * (1 - ratio) + Double(c2.b) * ratio
        return Color(red: r, green: g, blue: b)
    }

    var mixedHex: String {
        let c = mixedColor.getComponents()
        return String(format: "#%02X%02X%02X", Int(c.r * 255), Int(c.g * 255), Int(c.b * 255))
    }
}
