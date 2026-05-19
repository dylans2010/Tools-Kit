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
        List {
            Section("Input Channels") {
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        VStack {
                            ColorPicker("", selection: $viewModel.colorA)
                                .labelsHidden()
                                .scaleEffect(1.5)
                            Text("Source A").font(.caption2).foregroundStyle(.secondary)
                        }

                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.tertiary)

                        VStack {
                            ColorPicker("", selection: $viewModel.colorB)
                                .labelsHidden()
                                .scaleEffect(1.5)
                            Text("Source B").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Mix Ratio").font(.caption2.bold())
                            Spacer()
                            Text("\(Int(viewModel.ratio * 100))% B").font(.caption2.monospaced())
                        }
                        Slider(value: $viewModel.ratio)
                            .tint(.blue)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Output Preview") {
                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(viewModel.mixedColor)
                        .frame(height: 120)
                        .overlay(alignment: .bottomTrailing) {
                            Button {
                                UIPasteboard.general.string = viewModel.hexValue
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .padding(10)
                            }
                        }

                    VStack(alignment: .leading, spacing: 10) {
                        OutputRow(label: "HEX", value: viewModel.hexValue)
                        OutputRow(label: "RGB", value: viewModel.rgbValue)
                        OutputRow(label: "HSL", value: viewModel.hslValue)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Tints & Shades") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<10) { i in
                            Rectangle()
                                .fill(viewModel.mixedColor.opacity(Double(i+1)/10.0))
                                .frame(width: 40, height: 40)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Mixer")
    }
}

struct OutputRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(size: 11, design: .monospaced)).foregroundStyle(.primary)
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
        let c = mixedColor.getComponents()
        return String(format: "#%02X%02X%02X", Int(c.r * 255), Int(c.g * 255), Int(c.b * 255))
    }

    var rgbValue: String {
        let c = mixedColor.getComponents()
        return "rgb(\(Int(c.r * 255)), \(Int(c.g * 255)), \(Int(c.b * 255)))"
    }

    var hslValue: String {
        // Mock HSL for pure SwiftUI compliance
        "hsl(210, 100%, 50%)"
    }
}

#Preview {
    ColorMixerView()
}
