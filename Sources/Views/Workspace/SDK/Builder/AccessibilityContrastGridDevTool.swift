import SwiftUI

struct AccessibilityContrastGridDevTool: DevTool {
    let id = "accessibility-contrast-grid"
    let name = "Accessibility Contrast Grid"
    let category: DevToolCategory = .uiDesign
    let icon = "eye.fill"
    let description = "Check contrast ratios against WCAG accessibility standards"

    func render() -> some View {
        AccessibilityContrastGridView()
    }
}

struct AccessibilityContrastGridView: View {
    @State private var bgColor = Color.white
    @State private var fgColor = Color.black

    var body: some View {
        Form {
            ColorPicker("Background", selection: $bgColor)
            ColorPicker("Foreground", selection: $fgColor)

            Section("Preview") {
                Text("Sample Text")
                    .font(.title.bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(bgColor)
                    .foregroundColor(fgColor)
                    .cornerRadius(8)
            }

            Section("Compliance") {
                let ratio = calculateContrastRatio(fg: fgColor, bg: bgColor)
                LabeledContent("Contrast Ratio", value: String(format: "%.2f:1", ratio))
                LabeledContent("WCAG AA (Small)", value: ratio >= 4.5 ? "PASS" : "FAIL")
                    .foregroundStyle(ratio >= 4.5 ? .green : .red)
                LabeledContent("WCAG AAA (Small)", value: ratio >= 7.0 ? "PASS" : "FAIL")
                    .foregroundStyle(ratio >= 7.0 ? .green : .red)
                LabeledContent("WCAG AA (Large)", value: ratio >= 3.0 ? "PASS" : "FAIL")
                    .foregroundStyle(ratio >= 3.0 ? .green : .red)
            }
        }
    }

    private func calculateContrastRatio(fg: Color, bg: Color) -> Double {
        let fgL = relativeLuminance(color: fg)
        let bgL = relativeLuminance(color: bg)
        let l1 = max(fgL, bgL)
        let l2 = min(fgL, bgL)
        return (l1 + 0.05) / (l2 + 0.05)
    }

    private func relativeLuminance(color: Color) -> Double {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        func adjust(_ val: CGFloat) -> Double {
            return val <= 0.03928 ? Double(val / 12.92) : pow(Double((val + 0.055) / 1.055), 2.4)
        }

        return 0.2126 * adjust(r) + 0.7152 * adjust(g) + 0.0722 * adjust(b)
    }
}
