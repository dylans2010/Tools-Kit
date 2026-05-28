import SwiftUI

struct ColorConverterDevTool: DevTool {
    let id = "color-converter"
    let name = "Color Converter"
    let category = DevToolCategory.uiDesign
    let icon = "paintpalette.fill"
    let description = "Convert colors between Hex, RGB, HSL, CMYK with code snippets"

    func render() -> some View {
        ColorConverterView()
    }
}

struct ColorConverterView: View {
    @StateObject private var viewModel = ColorConverterViewModel()

    var body: some View {
        Form {
            Section(header: Text("Color Selection")) {
                ColorPicker("Choose Color", selection: $viewModel.selectedColor)

                Rectangle()
                    .fill(viewModel.selectedColor)
                    .frame(height: 60)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            }

            Section(header: Text("Hex Input")) {
                HStack {
                    Text("#")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    TextField("FF5733", text: $viewModel.hexInput)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit { viewModel.applyHex() }
                    Button("Apply") { viewModel.applyHex() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }

            Section(header: Text("Color Formats")) {
                copyRow(label: "HEX", value: viewModel.hexValue)
                copyRow(label: "RGB", value: viewModel.rgbValue)
                copyRow(label: "HSL", value: viewModel.hslValue)
                copyRow(label: "CMYK", value: viewModel.cmykValue)
                copyRow(label: "HSB", value: viewModel.hsbValue)
            }

            Section(header: Text("RGB Sliders")) {
                VStack(spacing: 8) {
                    HStack {
                        Text("R").font(.caption.bold()).foregroundStyle(.red).frame(width: 20)
                        Slider(value: $viewModel.red, in: 0...1)
                            .tint(.red)
                        Text("\(Int(viewModel.red * 255))").font(.caption.monospaced()).frame(width: 30)
                    }
                    HStack {
                        Text("G").font(.caption.bold()).foregroundStyle(.green).frame(width: 20)
                        Slider(value: $viewModel.green, in: 0...1)
                            .tint(.green)
                        Text("\(Int(viewModel.green * 255))").font(.caption.monospaced()).frame(width: 30)
                    }
                    HStack {
                        Text("B").font(.caption.bold()).foregroundStyle(.blue).frame(width: 20)
                        Slider(value: $viewModel.blue, in: 0...1)
                            .tint(.blue)
                        Text("\(Int(viewModel.blue * 255))").font(.caption.monospaced()).frame(width: 30)
                    }
                    HStack {
                        Text("A").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 20)
                        Slider(value: $viewModel.alpha, in: 0...1)
                        Text("\(Int(viewModel.alpha * 100))%").font(.caption.monospaced()).frame(width: 40)
                    }
                }
            }

            Section(header: Text("Code Snippets")) {
                VStack(alignment: .leading, spacing: 8) {
                    codeBlock(title: "SwiftUI", code: viewModel.swiftUISnippet)
                    codeBlock(title: "UIKit", code: viewModel.uiKitSnippet)
                    codeBlock(title: "CSS", code: viewModel.cssSnippet)
                    codeBlock(title: "Android (Kotlin)", code: viewModel.androidSnippet)
                }
            }

            Section(header: Text("Accessibility")) {
                LabeledContent("Luminance", value: String(format: "%.3f", viewModel.luminance))
                HStack {
                    Text("Contrast vs White")
                    Spacer()
                    Text(String(format: "%.1f:1", viewModel.contrastWhite))
                        .font(.caption.monospaced())
                    Image(systemName: viewModel.contrastWhite >= 4.5 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(viewModel.contrastWhite >= 4.5 ? .green : .red)
                        .font(.caption)
                }
                HStack {
                    Text("Contrast vs Black")
                    Spacer()
                    Text(String(format: "%.1f:1", viewModel.contrastBlack))
                        .font(.caption.monospaced())
                    Image(systemName: viewModel.contrastBlack >= 4.5 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(viewModel.contrastBlack >= 4.5 ? .green : .red)
                        .font(.caption)
                }
            }
        }
    }

    private func copyRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption.bold()).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
            Text(value).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            Spacer()
            Button {
                UIPasteboard.general.string = value
            } label: {
                Image(systemName: "doc.on.doc").font(.caption2)
            }
            .buttonStyle(.plain)
        }
    }

    private func codeBlock(title: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption.bold())
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                } label: {
                    Image(systemName: "doc.on.doc").font(.caption2)
                }
                .buttonStyle(.plain)
            }
            Text(code)
                .font(.system(.caption2, design: .monospaced))
                .padding(6)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(4)
                .textSelection(.enabled)
        }
    }
}

class ColorConverterViewModel: ObservableObject {
    @Published var selectedColor: Color = .blue {
        didSet { syncFromColor() }
    }
    @Published var hexInput = ""
    @Published var red: CGFloat = 0 { didSet { syncFromSliders() } }
    @Published var green: CGFloat = 0 { didSet { syncFromSliders() } }
    @Published var blue: CGFloat = 0 { didSet { syncFromSliders() } }
    @Published var alpha: CGFloat = 1 { didSet { syncFromSliders() } }

    private var isSyncing = false

    var hexValue: String {
        let c = selectedColor.getComponents()
        return String(format: "#%02X%02X%02X", Int(c.r * 255), Int(c.g * 255), Int(c.b * 255))
    }

    var rgbValue: String {
        let c = selectedColor.getComponents()
        return "rgb(\(Int(c.r * 255)), \(Int(c.g * 255)), \(Int(c.b * 255)))"
    }

    var hslValue: String {
        let c = selectedColor.getComponents()
        let (h, s, l) = rgbToHSL(r: Double(c.r), g: Double(c.g), b: Double(c.b))
        return "hsl(\(Int(h * 360)), \(Int(s * 100))%, \(Int(l * 100))%)"
    }

    var cmykValue: String {
        let c = selectedColor.getComponents()
        let r = Double(c.r); let g = Double(c.g); let b = Double(c.b)
        let k = 1 - max(r, g, b)
        guard k < 1 else { return "cmyk(0%, 0%, 0%, 100%)" }
        let cy = (1 - r - k) / (1 - k)
        let ma = (1 - g - k) / (1 - k)
        let ye = (1 - b - k) / (1 - k)
        return "cmyk(\(Int(cy * 100))%, \(Int(ma * 100))%, \(Int(ye * 100))%, \(Int(k * 100))%)"
    }

    var hsbValue: String {
        let c = selectedColor.getComponents()
        let r = Double(c.r); let g = Double(c.g); let b = Double(c.b)
        let maxV = max(r, g, b); let minV = min(r, g, b)
        let delta = maxV - minV
        var h: Double = 0
        if delta != 0 {
            if r == maxV { h = (g - b) / delta + (g < b ? 6 : 0) }
            else if g == maxV { h = (b - r) / delta + 2 }
            else { h = (r - g) / delta + 4 }
            h /= 6
        }
        let s = maxV == 0 ? 0 : delta / maxV
        return "hsb(\(Int(h * 360))°, \(Int(s * 100))%, \(Int(maxV * 100))%)"
    }

    var swiftUISnippet: String {
        let c = selectedColor.getComponents()
        return "Color(red: \(String(format: "%.3f", c.r)), green: \(String(format: "%.3f", c.g)), blue: \(String(format: "%.3f", c.b)))"
    }

    var uiKitSnippet: String {
        let c = selectedColor.getComponents()
        return "UIColor(red: \(String(format: "%.3f", c.r)), green: \(String(format: "%.3f", c.g)), blue: \(String(format: "%.3f", c.b)), alpha: 1.0)"
    }

    var cssSnippet: String {
        let c = selectedColor.getComponents()
        return "color: \(hexValue); /* \(rgbValue) */"
    }

    var androidSnippet: String {
        let c = selectedColor.getComponents()
        return "Color(0xFF\(String(format: "%02X%02X%02X", Int(c.r * 255), Int(c.g * 255), Int(c.b * 255))))"
    }

    var luminance: Double {
        let c = selectedColor.getComponents()
        return 0.2126 * Double(c.r) + 0.7152 * Double(c.g) + 0.0722 * Double(c.b)
    }

    var contrastWhite: Double {
        let l = luminance
        return (1.0 + 0.05) / (l + 0.05)
    }

    var contrastBlack: Double {
        let l = luminance
        return (l + 0.05) / (0.0 + 0.05)
    }

    func applyHex() {
        var hex = hexInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let intValue = Int(hex, radix: 16) else { return }
        let r = CGFloat((intValue >> 16) & 0xFF) / 255.0
        let g = CGFloat((intValue >> 8) & 0xFF) / 255.0
        let b = CGFloat(intValue & 0xFF) / 255.0
        isSyncing = true
        selectedColor = Color(red: Double(r), green: Double(g), blue: Double(b))
        self.red = r; self.green = g; self.blue = b
        isSyncing = false
    }

    private func syncFromColor() {
        guard !isSyncing else { return }
        isSyncing = true
        let c = selectedColor.getComponents()
        red = c.r; green = c.g; blue = c.b
        isSyncing = false
    }

    private func syncFromSliders() {
        guard !isSyncing else { return }
        isSyncing = true
        selectedColor = Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
        isSyncing = false
    }

    private func rgbToHSL(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
        let minV = min(r, min(g, b))
        let maxV = max(r, max(g, b))
        let delta = maxV - minV
        var h: Double = 0; var s: Double = 0; let l = (maxV + minV) / 2
        if delta != 0 {
            s = l < 0.5 ? delta / (maxV + minV) : delta / (2 - maxV - minV)
            if r == maxV { h = (g - b) / delta + (g < b ? 6 : 0) }
            else if g == maxV { h = (b - r) / delta + 2 }
            else { h = (r - g) / delta + 4 }
            h /= 6
        }
        return (h, s, l)
    }
}

#Preview {
    ColorConverterView()
}
