import SwiftUI

struct ColorMixerDevTool: DevTool {
    let id = "color-mixer"
    let name = "Color Mixer"
    let category = DevToolCategory.uiDesign
    let icon = "drop.fill"
    let description = "Blend two colors together"

    func render() -> some View {
        ColorMixerView()
    }
}

struct ColorMixerView: View {
    @StateObject private var viewModel = ColorMixerViewModel()

    var body: some View {
        Form {
            Section("Base Colors") {
                ColorPicker("Color A", selection: $viewModel.colorA)
                ColorPicker("Color B", selection: $viewModel.colorB)
            }

            Section("Ratio: \(Int(viewModel.ratio * 100))%") {
                Slider(value: $viewModel.ratio)
            }

            Section("Result") {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(viewModel.mixedColor)
                        .frame(height: 80)
                        .cornerRadius(12)

                    VStack(alignment: .leading) {
                        Text("Mixed Result").font(.headline)
                        Text(viewModel.hexValue).font(.caption.monospaced())
                    }
                }
            }
        }
    }
}

class ColorMixerViewModel: ObservableObject {
    @Published var colorA: Color = .red
    @Published var colorB: Color = .blue
    @Published var ratio: Double = 0.5

    var mixedColor: Color {
        let cA = colorA.getComponents()
        let cB = colorB.getComponents()

        return Color(red: cA.r * (1 - ratio) + cB.r * ratio,
                     green: cA.g * (1 - ratio) + cB.g * ratio,
                     blue: cA.b * (1 - ratio) + cB.b * ratio)
    }

    var hexValue: String {
        let components = mixedColor.getComponents()
        return String(format: "#%02X%02X%02X",
                      Int(components.r * 255),
                      Int(components.g * 255),
                      Int(components.b * 255))
    }
}

#Preview {
    ColorMixerView()
}
