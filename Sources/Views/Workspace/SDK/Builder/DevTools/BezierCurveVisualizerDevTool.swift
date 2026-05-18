import SwiftUI

struct BezierCurveVisualizerTool: DevTool {
    let id = UUID()
    let name = "Bezier Curve Visualizer"
    let category: DevToolCategory = .uiDesign
    let icon = "scribble.variable"
    let description = "Visualize and edit cubic bezier curves"
    func render() -> some View { BezierCurveVisualizerDevToolView() }
}

struct BezierCurveVisualizerDevToolView: View {
    @State private var cp1 = CGPoint(x: 0.25, y: 0.1)
    @State private var cp2 = CGPoint(x: 0.25, y: 1.0)

    var body: some View {
        Form {
            Section("Curve Preview") {
                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: h))
                            path.addCurve(
                                to: CGPoint(x: w, y: 0),
                                control1: CGPoint(x: cp1.x * w, y: h - cp1.y * h),
                                control2: CGPoint(x: cp2.x * w, y: h - cp2.y * h))
                        }
                        .stroke(Color.accentColor, lineWidth: 3)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: h))
                            path.addLine(to: CGPoint(x: cp1.x * w, y: h - cp1.y * h))
                        }
                        .stroke(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        Path { path in
                            path.move(to: CGPoint(x: w, y: 0))
                            path.addLine(to: CGPoint(x: cp2.x * w, y: h - cp2.y * h))
                        }
                        .stroke(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        Circle().fill(Color.red).frame(width: 14, height: 14)
                            .position(x: cp1.x * w, y: h - cp1.y * h)
                        Circle().fill(Color.blue).frame(width: 14, height: 14)
                            .position(x: cp2.x * w, y: h - cp2.y * h)
                    }
                }
                .frame(height: 200)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Section("Control Point 1 (Red)") {
                LabeledContent("X: \(String(format: "%.2f", cp1.x))") { Slider(value: $cp1.x, in: 0...1) }
                LabeledContent("Y: \(String(format: "%.2f", cp1.y))") { Slider(value: $cp1.y, in: -0.5...1.5) }
            }
            Section("Control Point 2 (Blue)") {
                LabeledContent("X: \(String(format: "%.2f", cp2.x))") { Slider(value: $cp2.x, in: 0...1) }
                LabeledContent("Y: \(String(format: "%.2f", cp2.y))") { Slider(value: $cp2.y, in: -0.5...1.5) }
            }
            Section("CSS Output") {
                Text("cubic-bezier(\(String(format: "%.2f", cp1.x)), \(String(format: "%.2f", cp1.y)), \(String(format: "%.2f", cp2.x)), \(String(format: "%.2f", cp2.y)))")
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Bezier Curve Visualizer")
    }
}
