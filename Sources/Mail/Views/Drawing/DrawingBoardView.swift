import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DrawingExport {
    let imageData: Data
    let fileName: String
}

struct DrawingBoardView: View {
    enum Tool: String, CaseIterable, Identifiable {
        case pen = "Pen"
        case marker = "Marker"
        case highlighter = "Highlighter"
        case pencil = "Pencil"
        case brush = "Brush"
        case spray = "Spray"
        case line = "Line"
        case doubleArrow = "Double Arrow"
        case arrow = "Arrow"
        case rectangle = "Rectangle"
        case ellipse = "Ellipse"
        case triangle = "Triangle"
        case diamond = "Diamond"
        case star = "Star"
        case callout = "Callout"
        case textBox = "Text Box"
        case eraser = "Eraser"

        var id: String { rawValue }
    }
    
    enum CanvasBackground: String, CaseIterable, Identifiable {
        case plain = "Plain"
        case graph = "Graph"
        case dot = "Dots"
        case dark = "Dark"
        
        var id: String { rawValue }
    }

    struct Stroke: Identifiable {
        let id = UUID()
        var points: [CGPoint]
        var color: Color
        var lineWidth: CGFloat
        var opacity: Double
        var tool: Tool
        var isDashed: Bool
        var isFilled: Bool
    }

    let onExport: (DrawingExport) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTool: Tool = .pen
    @State private var selectedColor: Color = .blue
    @State private var lineWidth: CGFloat = 4
    @State private var strokeOpacity: Double = 1
    @State private var useDashedStroke = false
    @State private var fillShapes = false
    @State private var showGrid = false
    @State private var snapToGrid = false
    @State private var backgroundStyle: CanvasBackground = .plain
    @State private var strokes: [Stroke] = []
    @State private var redoStrokes: [Stroke] = []
    @State private var inProgressStroke: Stroke?
    @State private var showToolSheet = false
    @State private var showStyleSheet = false
    @State private var showCanvasSheet = false
    @State private var showActionsSheet = false

    private static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmssSSS"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                controls

                GeometryReader { geo in
                    ZStack {
                        canvasBackground
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        Canvas { context, _ in
                            if showGrid {
                                drawGrid(in: &context, size: geo.size)
                            }
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showActionsSheet = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showToolSheet) { toolSheet }
            .sheet(isPresented: $showStyleSheet) { styleSheet }
            .sheet(isPresented: $showCanvasSheet) { canvasSheet }
            .sheet(isPresented: $showActionsSheet) { actionsSheet }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { showToolSheet = true } label: {
                    Label(selectedTool.rawValue, systemImage: "paintbrush.pointed")
                }
                .buttonStyle(.borderedProminent)
                Button { showStyleSheet = true } label: {
                    Label("Style", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.bordered)
                Button { showCanvasSheet = true } label: {
                    Label("Canvas", systemImage: "square.grid.3x3")
                }
                .buttonStyle(.bordered)
            }
            .font(.subheadline.weight(.semibold))
        }
    }

    private func drawingGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = adjustedPoint(value.location, in: size)
                if selectedTool == .eraser {
                    eraseStroke(near: location)
                    return
                }
                switch selectedTool {
                case .pen, .highlighter, .pencil, .brush, .marker:
                    if inProgressStroke == nil {
                        inProgressStroke = Stroke(
                            points: [location],
                            color: selectedColor,
                            lineWidth: currentStrokeWidth,
                            opacity: drawingOpacity(for: selectedTool),
                            tool: selectedTool,
                            isDashed: useDashedStroke,
                            isFilled: false
                        )
                    } else {
                        inProgressStroke?.points.append(location)
                    }
                case .line, .rectangle, .ellipse, .arrow, .doubleArrow, .triangle, .diamond, .star, .callout, .textBox:
                    let start = inProgressStroke?.points.first ?? adjustedPoint(value.startLocation, in: size)
                    inProgressStroke = Stroke(
                        points: [start, location],
                        color: selectedColor,
                        lineWidth: lineWidth,
                        opacity: strokeOpacity,
                        tool: selectedTool,
                        isDashed: useDashedStroke,
                        isFilled: fillShapes
                    )
                case .spray:
                    let dots = (0..<7).map { _ in
                        CGPoint(x: location.x + .random(in: -8...8), y: location.y + .random(in: -8...8))
                    }
                    inProgressStroke = Stroke(
                        points: dots,
                        color: selectedColor,
                        lineWidth: max(1, lineWidth / 2),
                        opacity: 0.55,
                        tool: selectedTool,
                        isDashed: false,
                        isFilled: true
                    )
                    if let sprayStroke = inProgressStroke {
                        strokes.append(sprayStroke)
                    }
                case .eraser:
                    break
                }
            }
            .onEnded { _ in
                if let inProgressStroke {
                    strokes.append(inProgressStroke)
                    redoStrokes.removeAll()
                }
                inProgressStroke = nil
            }
    }

    private func draw(_ stroke: Stroke, in context: inout GraphicsContext) {
        guard !stroke.points.isEmpty else { return }

        switch stroke.tool {
        case .pen, .highlighter, .pencil, .brush, .marker:
            var path = Path()
            path.move(to: stroke.points[0])
            for point in stroke.points.dropFirst() {
                path.addLine(to: point)
            }
            context.opacity = stroke.opacity
            context.stroke(
                path,
                with: .color(stroke.color),
                style: StrokeStyle(
                    lineWidth: stroke.lineWidth,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: stroke.isDashed ? [10, 5] : []
                )
            )

        case .line:
            guard stroke.points.count >= 2 else { return }
            var path = Path()
            path.move(to: stroke.points[0])
            path.addLine(to: stroke.points[1])
            context.opacity = stroke.opacity
            context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, dash: stroke.isDashed ? [10, 5] : []))

        case .arrow:
            guard stroke.points.count >= 2 else { return }
            drawArrow(from: stroke.points[0], to: stroke.points[1], stroke: stroke, context: &context)
        case .doubleArrow:
            guard stroke.points.count >= 2 else { return }
            drawArrow(from: stroke.points[0], to: stroke.points[1], stroke: stroke, context: &context)
            drawArrow(from: stroke.points[1], to: stroke.points[0], stroke: stroke, context: &context)

        case .rectangle:
            guard stroke.points.count >= 2 else { return }
            let rect = CGRect(from: stroke.points[0], to: stroke.points[1])
            let path = Path(roundedRect: rect, cornerRadius: 6)
            context.opacity = stroke.opacity
            if stroke.isFilled {
                context.fill(path, with: .color(stroke.color.opacity(0.18)))
            }
            context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth, dash: stroke.isDashed ? [10, 5] : []))

        case .ellipse:
            guard stroke.points.count >= 2 else { return }
            let rect = CGRect(from: stroke.points[0], to: stroke.points[1])
            let path = Path(ellipseIn: rect)
            context.opacity = stroke.opacity
            if stroke.isFilled {
                context.fill(path, with: .color(stroke.color.opacity(0.18)))
            }
            context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth, dash: stroke.isDashed ? [10, 5] : []))
        case .triangle:
            guard stroke.points.count >= 2 else { return }
            drawPolygon(sides: 3, from: stroke, in: &context)
        case .diamond:
            guard stroke.points.count >= 2 else { return }
            let rect = CGRect(from: stroke.points[0], to: stroke.points[1])
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
            drawFillAndStroke(path: path, stroke: stroke, context: &context)
        case .star:
            guard stroke.points.count >= 2 else { return }
            drawStar(from: stroke, in: &context)
        case .callout:
            guard stroke.points.count >= 2 else { return }
            let rect = CGRect(from: stroke.points[0], to: stroke.points[1])
            var bubble = Path(roundedRect: rect, cornerRadius: 14)
            bubble.move(to: CGPoint(x: rect.midX - 10, y: rect.maxY))
            bubble.addLine(to: CGPoint(x: rect.midX + 3, y: rect.maxY))
            bubble.addLine(to: CGPoint(x: rect.midX - 8, y: rect.maxY + 16))
            bubble.closeSubpath()
            drawFillAndStroke(path: bubble, stroke: stroke, context: &context)
        case .textBox:
            guard stroke.points.count >= 2 else { return }
            let rect = CGRect(from: stroke.points[0], to: stroke.points[1])
            let path = Path(roundedRect: rect, cornerRadius: 8)
            context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth))
            context.draw(Text("Text").font(.caption.bold()), at: CGPoint(x: rect.midX, y: rect.midY))
        case .spray:
            for point in stroke.points {
                let dotRect = CGRect(x: point.x, y: point.y, width: stroke.lineWidth, height: stroke.lineWidth)
                context.fill(Path(ellipseIn: dotRect), with: .color(stroke.color.opacity(stroke.opacity)))
            }
        case .eraser:
            break
        }
    }

    private func exportDrawing() {
        let renderer = ImageRenderer(content: exportCanvas)
        if let uiImage = renderer.uiImage, let data = uiImage.pngData() {
            onExport(DrawingExport(imageData: data, fileName: "Drawing-\(Self.fileNameFormatter.string(from: Date())).png"))
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
    
    private var canvasBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(backgroundFill)
    }
    
    private var backgroundFill: some ShapeStyle {
        switch backgroundStyle {
        case .plain:
            return AnyShapeStyle(Color(.secondarySystemBackground))
        case .graph:
            return AnyShapeStyle(LinearGradient(colors: [Color.white, Color.blue.opacity(0.08)], startPoint: .top, endPoint: .bottom))
        case .dot:
            return AnyShapeStyle(LinearGradient(colors: [Color.white, Color.mint.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .dark:
            return AnyShapeStyle(LinearGradient(colors: [Color.black.opacity(0.92), Color.indigo.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }
    
    private func drawGrid(in context: inout GraphicsContext, size: CGSize) {
        var path = Path()
        let spacing: CGFloat = snapToGrid ? 20 : 24
        stride(from: CGFloat.zero, through: size.width, by: spacing).forEach { x in
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }
        stride(from: CGFloat.zero, through: size.height, by: spacing).forEach { y in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(path, with: .color(.gray.opacity(backgroundStyle == .dark ? 0.25 : 0.15)), style: StrokeStyle(lineWidth: 0.8))
    }
    
    private func drawArrow(from start: CGPoint, to end: CGPoint, stroke: Stroke, context: inout GraphicsContext) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.opacity = stroke.opacity
        context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, dash: stroke.isDashed ? [10, 5] : []))
        
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(12, stroke.lineWidth * 2.2)
        let arrow1 = CGPoint(x: end.x - headLength * cos(angle - .pi / 6), y: end.y - headLength * sin(angle - .pi / 6))
        let arrow2 = CGPoint(x: end.x - headLength * cos(angle + .pi / 6), y: end.y - headLength * sin(angle + .pi / 6))
        var head = Path()
        head.move(to: end)
        head.addLine(to: arrow1)
        head.move(to: end)
        head.addLine(to: arrow2)
        context.stroke(head, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round))
    }

    private func drawPolygon(sides: Int, from stroke: Stroke, in context: inout GraphicsContext) {
        let rect = CGRect(from: stroke.points[0], to: stroke.points[1])
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<sides {
            let angle = (Double(i) * (2 * .pi / Double(sides))) - (.pi / 2)
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        drawFillAndStroke(path: path, stroke: stroke, context: &context)
    }

    private func drawStar(from stroke: Stroke, in context: inout GraphicsContext) {
        let rect = CGRect(from: stroke.points[0], to: stroke.points[1])
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.45
        var path = Path()
        for i in 0..<10 {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = (Double(i) * .pi / 5) - (.pi / 2)
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        drawFillAndStroke(path: path, stroke: stroke, context: &context)
    }

    private func drawFillAndStroke(path: Path, stroke: Stroke, context: inout GraphicsContext) {
        context.opacity = stroke.opacity
        if stroke.isFilled { context.fill(path, with: .color(stroke.color.opacity(0.18))) }
        context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.lineWidth, dash: stroke.isDashed ? [10, 5] : []))
    }

    private func drawingOpacity(for tool: Tool) -> Double {
        switch tool {
        case .highlighter: return 0.35
        case .pencil: return 0.6
        default: return strokeOpacity
        }
    }

    private var currentStrokeWidth: CGFloat {
        switch selectedTool {
        case .marker: return lineWidth * 1.4
        case .brush: return lineWidth * 1.8
        case .pencil: return max(1, lineWidth * 0.6)
        default: return lineWidth
        }
    }

    private var toolSheet: some View {
        NavigationStack {
            List {
                ForEach(Tool.allCases) { tool in
                    Button {
                        selectedTool = tool
                        showToolSheet = false
                    } label: {
                        HStack {
                            Text(tool.rawValue)
                            Spacer()
                            if selectedTool == tool { Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue) }
                        }
                    }
                }
            }
            .navigationTitle("Tools")
        }
    }

    private var styleSheet: some View {
        NavigationStack {
            Form {
                ColorPicker("Color", selection: $selectedColor)
                HStack {
                    Text("Size")
                    Slider(value: $lineWidth, in: 1...20)
                    Text(Int(lineWidth).description).font(.caption)
                }
                Toggle("Dashed", isOn: $useDashedStroke)
                Toggle("Fill Shapes", isOn: $fillShapes)
                HStack {
                    Text("Opacity")
                    Slider(value: $strokeOpacity, in: 0.2...1)
                }
            }
            .navigationTitle("Style")
        }
    }

    private var canvasSheet: some View {
        NavigationStack {
            Form {
                Picker("Background", selection: $backgroundStyle) {
                    ForEach(CanvasBackground.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                Toggle("Grid", isOn: $showGrid)
                Toggle("Snap to Grid", isOn: $snapToGrid)
            }
            .navigationTitle("Canvas")
        }
    }

    private var actionsSheet: some View {
        NavigationStack {
            List {
                Button("Undo", action: undo).disabled(strokes.isEmpty)
                Button("Redo", action: redo).disabled(redoStrokes.isEmpty)
                Button("Clear", role: .destructive, action: clearCanvas)
                Button("Export PNG", action: exportDrawing).disabled(strokes.isEmpty)
            }
            .navigationTitle("Actions")
        }
    }

    private func undo() {
        guard let last = strokes.popLast() else { return }
        redoStrokes.append(last)
    }

    private func redo() {
        guard let last = redoStrokes.popLast() else { return }
        strokes.append(last)
    }

    private func clearCanvas() {
        strokes.removeAll()
        redoStrokes.removeAll()
        inProgressStroke = nil
    }
    
    private func adjustedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let clamped = clamp(point, in: size)
        guard snapToGrid else { return clamped }
        let spacing: CGFloat = 20
        return CGPoint(
            x: (clamped.x / spacing).rounded() * spacing,
            y: (clamped.y / spacing).rounded() * spacing
        )
    }
    
    private func eraseStroke(near point: CGPoint) {
        let threshold = max(12, lineWidth * 2.8)
        strokes.removeAll { stroke in
            stroke.points.contains { candidate in
                hypot(candidate.x - point.x, candidate.y - point.y) <= threshold
            }
        }
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
