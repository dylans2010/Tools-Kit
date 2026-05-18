import SwiftUI

struct TypographyScaleTool: DevTool {
    let id = UUID()
    let name = "Typography Scale"
    let category: DevToolCategory = .uiDesign
    let icon = "textformat.size"
    let description = "Preview iOS typography scale and custom sizes"
    func render() -> some View { TypographyScaleDevToolView() }
}

struct TypographyScaleDevToolView: View {
    @State private var baseSize: Double = 16
    @State private var scaleRatio: Double = 1.25

    private var scales: [(String, Font)] {
        [("Large Title", .largeTitle), ("Title", .title), ("Title 2", .title2),
         ("Title 3", .title3), ("Headline", .headline), ("Body", .body),
         ("Callout", .callout), ("Subheadline", .subheadline),
         ("Footnote", .footnote), ("Caption", .caption), ("Caption 2", .caption2)]
    }

    private var customScales: [(String, Double)] {
        let names = ["Display", "H1", "H2", "H3", "Body", "Small", "XS"]
        return names.enumerated().map { idx, name in
            (name, baseSize * pow(scaleRatio, Double(3 - idx)))
        }
    }

    var body: some View {
        Form {
            Section("System Fonts") {
                ForEach(scales, id: \.0) { name, font in
                    Text(name).font(font)
                }
            }
            Section("Custom Scale") {
                LabeledContent("Base: \(Int(baseSize))pt") { Slider(value: $baseSize, in: 10...24, step: 1) }
                LabeledContent("Ratio: \(String(format: "%.2f", scaleRatio))") { Slider(value: $scaleRatio, in: 1.1...1.5) }
            }
            Section("Generated Scale") {
                ForEach(customScales, id: \.0) { name, size in
                    HStack {
                        Text(name).font(.system(size: min(size, 40)))
                        Spacer()
                        Text("\(String(format: "%.1f", size))pt")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Typography Scale")
    }
}
