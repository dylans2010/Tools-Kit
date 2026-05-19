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
    @State private var showingCodeSheet = false

    var body: some View {
        List {
            Section("Color Selection") {
                VStack(spacing: 16) {
                    ColorPicker("Active Color", selection: $viewModel.selectedColor)
                        .font(.headline)

                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.selectedColor)
                            .frame(height: 100)
                            .shadow(color: .black.opacity(0.1), radius: 5)

                        Text(viewModel.hexValue)
                            .font(.system(.caption2, design: .monospaced).bold())
                            .padding(6)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                            .padding(8)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Value Formats") {
                ColorValueRow(label: "HEX", value: viewModel.hexValue)
                ColorValueRow(label: "RGB", value: viewModel.rgbValue)
                ColorValueRow(label: "HSL", value: viewModel.hslValue)
                ColorValueRow(label: "CMYK", value: viewModel.cmykValue)
            }

            Section("Contrast Checker") {
                HStack(spacing: 20) {
                    VStack {
                        Text("On White")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text("Aa")
                            .font(.title.bold())
                            .foregroundStyle(viewModel.selectedColor)
                            .frame(width: 60, height: 60)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.2)))
                    }

                    VStack {
                        Text("On Black")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text("Aa")
                            .font(.title.bold())
                            .foregroundStyle(viewModel.selectedColor)
                            .frame(width: 60, height: 60)
                            .background(Color.black, in: RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        ContrastBadge(score: viewModel.contrastScoreWhite, label: "WCAG White")
                        ContrastBadge(score: viewModel.contrastScoreBlack, label: "WCAG Black")
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Code Export") {
                Button {
                    showingCodeSheet = true
                } label: {
                    Label("View Code Snippets", systemImage: "chevron.left.forwardslash.chevron.right")
                }

                Button {
                    UIPasteboard.general.string = viewModel.swiftUISnippet
                } label: {
                    Label("Copy SwiftUI Color", systemImage: "doc.on.doc")
                }
            }

            Section("Recently Used") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.recentColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .onTapGesture { viewModel.selectedColor = color }
                        }
                    }
                }
            }
        }
        .navigationTitle("Color Converter")
        .sheet(isPresented: $showingCodeSheet) {
            ColorCodeView(viewModel: viewModel)
        }
    }
}

struct ColorValueRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .textSelection(.enabled)

            Button {
                UIPasteboard.general.string = value
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
    }
}

struct ContrastBadge: View {
    let score: Double
    let label: String

    var body: some View {
        HStack {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(String(format: "%.1f", score))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(score > 4.5 ? .green : (score > 3 ? .orange : .red), in: Capsule())
                .foregroundStyle(.white)
        }
    }
}

class ColorConverterViewModel: ObservableObject {
    @Published var selectedColor: Color = .blue {
        didSet {
            if !recentColors.contains(selectedColor) {
                recentColors.insert(selectedColor, at: 0)
                if recentColors.count > 10 { recentColors.removeLast() }
            }
        }
    }

    @Published var recentColors: [Color] = [.blue, .red, .green, .orange, .purple]

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

    var cmykValue: String {
        let components = selectedColor.getComponents()
        let r = Double(components.r)
        let g = Double(components.g)
        let b = Double(components.b)

        let k = 1.0 - max(r, max(g, b))
        if k == 1.0 { return "cmyk(0, 0, 0, 100%)" }

        let c = (1.0 - r - k) / (1.0 - k)
        let m = (1.0 - g - k) / (1.0 - k)
        let y = (1.0 - b - k) / (1.0 - k)

        return "cmyk(\(Int(c*100))%, \(Int(m*100))%, \(Int(y*100))%, \(Int(k*100))%)"
    }

    var contrastScoreWhite: Double { calculateContrast(with: .white) }
    var contrastScoreBlack: Double { calculateContrast(with: .black) }

    var swiftUISnippet: String {
        "Color(red: \(String(format: "%.3f", selectedColor.getComponents().r)), green: \(String(format: "%.3f", selectedColor.getComponents().g)), blue: \(String(format: "%.3f", selectedColor.getComponents().b)))"
    }

    var uiColorSnippet: String {
        "UIColor(red: \(String(format: "%.3f", selectedColor.getComponents().r)), green: \(String(format: "%.3f", selectedColor.getComponents().g)), blue: \(String(format: "%.3f", selectedColor.getComponents().b)), alpha: 1.0)"
    }

    var cssSnippet: String {
        "background-color: \(hexValue);"
    }

    private func calculateContrast(with bg: Color) -> Double {
        let l1 = relativeLuminance(for: selectedColor.getComponents())
        let l2 = relativeLuminance(for: bg.getComponents())
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(for comp: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)) -> Double {
        let rs = comp.r <= 0.03928 ? comp.r / 12.92 : pow((comp.r + 0.055) / 1.055, 2.4)
        let gs = comp.g <= 0.03928 ? comp.g / 12.92 : pow((comp.g + 0.055) / 1.055, 2.4)
        let bs = comp.b <= 0.03928 ? comp.b / 12.92 : pow((comp.b + 0.055) / 1.055, 2.4)
        return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs
    }
}

struct ColorCodeView: View {
    @ObservedObject var viewModel: ColorConverterViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                CodeSection(title: "SwiftUI", code: viewModel.swiftUISnippet)
                CodeSection(title: "UIKit", code: viewModel.uiColorSnippet)
                CodeSection(title: "CSS", code: viewModel.cssSnippet)
                CodeSection(title: "React Native", code: "const styles = { color: '\(viewModel.hexValue)' };")
            }
            .navigationTitle("Code Snippets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

struct CodeSection: View {
    let title: String
    let code: String

    var body: some View {
        Section(title) {
            VStack(alignment: .leading, spacing: 8) {
                Text(code)
                    .font(.system(.caption2, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(6)

                Button {
                    UIPasteboard.general.string = code
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    ColorConverterView()
}
