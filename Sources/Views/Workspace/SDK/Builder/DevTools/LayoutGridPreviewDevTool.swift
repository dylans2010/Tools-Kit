import SwiftUI

struct LayoutGridPreviewTool: DevTool {
    let id = UUID()
    let name = "Layout Grid Preview"
    let category: DevToolCategory = .uiDesign
    let icon = "square.grid.3x3"
    let description = "Visualize layout grid systems"
    func render() -> some View { LayoutGridPreviewDevToolView() }
}

struct LayoutGridPreviewDevToolView: View {
    @State private var columns: Double = 4
    @State private var spacing: Double = 8
    @State private var margin: Double = 16

    var body: some View {
        Form {
            Section("Preview") {
                GeometryReader { geo in
                    let w = geo.size.width - margin * 2
                    let cols = Int(columns)
                    let totalSpacing = spacing * Double(cols - 1)
                    let colWidth = (w - totalSpacing) / Double(cols)
                    HStack(spacing: spacing) {
                        ForEach(0..<cols, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: colWidth, height: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, margin)
                }
                .frame(height: 220)
            }
            Section("Configuration") {
                LabeledContent("Columns: \(Int(columns))") { Slider(value: $columns, in: 1...12, step: 1) }
                LabeledContent("Spacing: \(Int(spacing))pt") { Slider(value: $spacing, in: 0...24, step: 2) }
                LabeledContent("Margin: \(Int(margin))pt") { Slider(value: $margin, in: 0...40, step: 4) }
            }
            Section("Info") {
                LabeledContent("Grid System", value: "\(Int(columns))-column")
                LabeledContent("Gutter", value: "\(Int(spacing))pt")
                LabeledContent("Margin", value: "\(Int(margin))pt")
            }
        }
        .navigationTitle("Layout Grid Preview")
    }
}
