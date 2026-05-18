import SwiftUI

struct ColorConverterTool: DevTool {
    let id = UUID()
    let name = "Color Converter"
    let category: DevToolCategory = .uiDesign
    let icon = "paintpalette"
    let description = "Convert colors between HEX, RGB, and HSL"
    func render() -> some View { ColorConverterDevToolView() }
}

struct ColorConverterDevToolView: View {
    @State private var hexInput = "FF5733"
    @State private var red: Double = 255
    @State private var green: Double = 87
    @State private var blue: Double = 51

    private var currentColor: Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }

    var body: some View {
        Form {
            Section("Preview") {
                RoundedRectangle(cornerRadius: 12)
                    .fill(currentColor)
                    .frame(height: 80)
            }
            Section("HEX") {
                HStack {
                    Text("#")
                    TextField("HEX", text: $hexInput)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button("Apply") { applyHex() }
                }
            }
            Section("RGB") {
                LabeledContent("Red: \(Int(red))") { Slider(value: $red, in: 0...255, step: 1) }
                LabeledContent("Green: \(Int(green))") { Slider(value: $green, in: 0...255, step: 1) }
                LabeledContent("Blue: \(Int(blue))") { Slider(value: $blue, in: 0...255, step: 1) }
                Button("Update HEX") {
                    hexInput = String(format: "%02X%02X%02X", Int(red), Int(green), Int(blue))
                }
            }
            Section("Values") {
                LabeledContent("HEX", value: "#\(String(format: "%02X%02X%02X", Int(red), Int(green), Int(blue)))")
                LabeledContent("RGB", value: "\(Int(red)), \(Int(green)), \(Int(blue))")
                let h = hue(r: red/255, g: green/255, b: blue/255)
                let s = saturation(r: red/255, g: green/255, b: blue/255)
                let l = lightness(r: red/255, g: green/255, b: blue/255)
                LabeledContent("HSL", value: "\(Int(h))°, \(Int(s*100))%, \(Int(l*100))%")
            }
        }
        .navigationTitle("Color Converter")
    }

    private func applyHex() {
        let hex = hexInput.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let val = UInt64(hex, radix: 16) else { return }
        red = Double((val >> 16) & 0xFF)
        green = Double((val >> 8) & 0xFF)
        blue = Double(val & 0xFF)
    }

    private func hue(r: Double, g: Double, b: Double) -> Double {
        let mx = max(r, g, b), mn = min(r, g, b)
        guard mx != mn else { return 0 }
        let d = mx - mn
        var h: Double
        if mx == r { h = (g - b) / d + (g < b ? 6 : 0) }
        else if mx == g { h = (b - r) / d + 2 }
        else { h = (r - g) / d + 4 }
        return h * 60
    }
    private func saturation(r: Double, g: Double, b: Double) -> Double {
        let mx = max(r, g, b), mn = min(r, g, b)
        let l = (mx + mn) / 2
        guard mx != mn else { return 0 }
        return l > 0.5 ? (mx - mn) / (2 - mx - mn) : (mx - mn) / (mx + mn)
    }
    private func lightness(r: Double, g: Double, b: Double) -> Double {
        (max(r, g, b) + min(r, g, b)) / 2
    }
}
