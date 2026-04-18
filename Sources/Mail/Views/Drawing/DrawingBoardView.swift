import SwiftUI
import UIKit

struct DrawingExport {
    let imageData: Data
    let fileName: String
}

struct DrawingBoardView: View {
    enum Tool: String, CaseIterable, Identifiable {
        case pen = "Pen"
        case line = "Line"
        case rectangle = "Rectangle"
        case ellipse = "Ellipse"

        var id: String { rawValue }
    }

    struct Stroke: Identifiable {
        let id = UUID()
        var points: [CGPoint]
        var color: Color
        var lineWidth: CGFloat
        var tool: Tool
    }

    let onExport: (DrawingExport) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTool: Tool = .pen
    @State private var selectedColor: Color = .blue
    @State private var lineWidth: CGFloat = 4
    @State private var strokes: [Stroke] = []
    @State private var inProgressStroke: Stroke?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                controls

                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))

                        Canvas { context, _ in
                            for stroke in strokes {
                                draw(stroke, in: &context)
                            }
                            if let inProgressStroke {
                                draw(inProgressStroke, in: &context)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .gesture(drawingGesture(in: geo.size))
                    }
                }
            }
            .padding()
            .navigationTitle("Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export PNG") {
                        exportDrawing()
                    }
                    .disabled(strokes.isEmpty)
                }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Picker("Tool", selection: $selectedTool) {
                ForEach(Tool.allCases) { tool in
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

            HStack {
                Button("Undo") {
                    _ = strokes.popLast()
                }
                .disabled(strokes.isEmpty)

                Spacer()

                Button("Clear", role: .destructive) {
                    strokes.removeAll()
                    inProgressStroke = nil
                }
                .disabled(strokes.isEmpty && inProgressStroke == nil)
            }
            .font(.subheadline.weight(.semibold))
        }
    }

    private func drawingGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = clamp(value.location, in: size)
                switch selectedTool {
                case .pen:
                    if inProgressStroke == nil {
                        inProgressStroke = Stroke(points: [location], color: selectedColor, lineWidth: lineWidth, tool: .pen)
                    } else {
                        inProgressStroke?.points.append(location)
                    }
                case .line, .rectangle, .ellipse:
                    let start = inProgressStroke?.points.first ?? clamp(value.startLocation, in: size)
                    inProgressStroke = Stroke(points: [start, location], color: selectedColor, lineWidth: lineWidth, tool: selectedTool)
                }
            }
            .onEnded { _ in
                if let inProgressStroke {
                    strokes.append(inProgressStroke)
                }
                inProgressStroke = nil
            }
    }

    private func draw(_ stroke: Stroke, in context: inout GraphicsContext) {
        guard !stroke.points.isEmpty else { return }

        switch stroke.tool {
        case .pen:
            var path = Path()
            path.move(to: stroke.points[0])
            for point in stroke.points.dropFirst() {
                path.addLine(to: point)
            }
            context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round))

        case .line:
            guard stroke.points.count >= 2 else { return }
            var path = Path()
            path.move(to: stroke.points[0])
            path.addLine(to: stroke.points[1])
            context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round))

        case .rectangle:
            guard stroke.points.count >= 2 else { return }
            let rect = CGRect(from: stroke.points[0], to: stroke.points[1])
            context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth))

        case .ellipse:
            guard stroke.points.count >= 2 else { return }
            let rect = CGRect(from: stroke.points[0], to: stroke.points[1])
            context.stroke(Path(ellipseIn: rect), with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth))
        }
    }

    private func exportDrawing() {
        let renderer = ImageRenderer(content: exportCanvas)
        if let uiImage = renderer.uiImage, let data = uiImage.pngData() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            onExport(DrawingExport(imageData: data, fileName: "Drawing-\(formatter.string(from: Date())).png"))
            dismiss()
        }
    }

    private var exportCanvas: some View {
        Canvas { context, _ in
            for stroke in strokes {
                draw(stroke, in: &context)
            }
        }
        .frame(width: 1200, height: 800)
        .background(.white)
    }

    private func clamp(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(0, point.x), size.width),
            y: min(max(0, point.y), size.height)
        )
    }
}

private extension CGRect {
    init(from start: CGPoint, to end: CGPoint) {
        self.init(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}
