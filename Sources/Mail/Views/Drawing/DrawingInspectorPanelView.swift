import SwiftUI

struct DrawingInspectorPanelView: View {
    @Binding var selectedTool: DrawingBoardView.Tool
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var strokeOpacity: Double
    @Binding var useDashedStroke: Bool
    @Binding var fillShapes: Bool
    @Binding var showGrid: Bool
    @Binding var snapToGrid: Bool

    var body: some View {
        VStack(spacing: 10) {
            Picker("Tool", selection: $selectedTool) {
                ForEach(DrawingBoardView.Tool.allCases) { tool in
                    Text(tool.rawValue).tag(tool)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                ColorPicker("Color", selection: $selectedColor)
                Spacer()
                Text("Size")
                Slider(value: $lineWidth, in: 1...16)
                    .frame(width: 140)
                Text(Int(lineWidth).description)
                    .font(.caption)
                    .frame(width: 26)
            }

            HStack(spacing: 10) {
                Text("Opacity")
                    .font(.subheadline)
                Slider(value: $strokeOpacity, in: 0.2...1)
                Text("\(Int(strokeOpacity * 100))%")
                    .font(.caption)
                    .frame(width: 38)
            }

            HStack {
                Toggle("Dashed", isOn: $useDashedStroke)
                Toggle("Fill Shapes", isOn: $fillShapes)
            }
            .font(.caption.weight(.semibold))

            HStack {
                Toggle("Grid", isOn: $showGrid)
                Toggle("Snap", isOn: $snapToGrid)
            }
            .font(.caption.weight(.semibold))
        }
    }
}
