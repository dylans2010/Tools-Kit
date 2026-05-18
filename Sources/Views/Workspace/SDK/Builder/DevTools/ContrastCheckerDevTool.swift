import SwiftUI

struct ContrastCheckerTool: DevTool {
    let id = UUID()
    let name = "Contrast Checker"
    let category: DevToolCategory = .uiDesign
    let icon = "circle.lefthalf.filled"
    let description = "Check WCAG color contrast ratios"
    func render() -> some View { ContrastCheckerDevToolView() }
}

struct ContrastCheckerDevToolView: View {
    @State private var fgHue: Double = 0
    @State private var fgSat: Double = 0
    @State private var fgBri: Double = 0.1
    @State private var bgHue: Double = 0
    @State private var bgSat: Double = 0
    @State private var bgBri: Double = 1.0

    private var fgColor: Color { Color(hue: fgHue, saturation: fgSat, brightness: fgBri) }
    private var bgColor: Color { Color(hue: bgHue, saturation: bgSat, brightness: bgBri) }

    private var contrastRatio: Double {
        let fgL = relativeLuminance(h: fgHue, s: fgSat, b: fgBri)
        let bgL = relativeLuminance(h: bgHue, s: bgSat, b: bgBri)
        let lighter = max(fgL, bgL)
        let darker = min(fgL, bgL)
        return (lighter + 0.05) / (darker + 0.05)
    }

    var body: some View {
        Form {
            Section("Preview") {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(bgColor)
                    VStack(spacing: 8) {
                        Text("Sample Text").font(.title2.bold()).foregroundStyle(fgColor)
                        Text("Small body text for reading").font(.body).foregroundStyle(fgColor)
                    }
                }
                .frame(height: 100)
            }
            Section("Foreground") {
                LabeledContent("Hue") { Slider(value: $fgHue) }
                LabeledContent("Saturation") { Slider(value: $fgSat) }
                LabeledContent("Brightness") { Slider(value: $fgBri) }
            }
            Section("Background") {
                LabeledContent("Hue") { Slider(value: $bgHue) }
                LabeledContent("Saturation") { Slider(value: $bgSat) }
                LabeledContent("Brightness") { Slider(value: $bgBri) }
            }
            Section("Results") {
                LabeledContent("Contrast Ratio", value: String(format: "%.2f:1", contrastRatio))
                LabeledContent("WCAG AA (Normal)") { passFailBadge(contrastRatio >= 4.5) }
                LabeledContent("WCAG AA (Large)") { passFailBadge(contrastRatio >= 3.0) }
                LabeledContent("WCAG AAA (Normal)") { passFailBadge(contrastRatio >= 7.0) }
                LabeledContent("WCAG AAA (Large)") { passFailBadge(contrastRatio >= 4.5) }
            }
        }
        .navigationTitle("Contrast Checker")
    }

    @ViewBuilder
    private func passFailBadge(_ passes: Bool) -> some View {
        Text(passes ? "PASS" : "FAIL")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(passes ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
            .foregroundStyle(passes ? .green : .red)
            .clipShape(Capsule())
    }

    private func relativeLuminance(h: Double, s: Double, b: Double) -> Double {
        let c = b * s
        let x = c * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = b - c
        var r = m, g = m, bl = m
        let sector = Int(h * 6) % 6
        switch sector {
        case 0: r += c; g += x
        case 1: r += x; g += c
        case 2: g += c; bl += x
        case 3: g += x; bl += c
        case 4: r += x; bl += c
        case 5: r += c; bl += x
        default: break
        }
        func linearize(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(bl)
    }
}
