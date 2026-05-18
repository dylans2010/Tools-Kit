import SwiftUI

struct BezierCurveVisualizerDevTool: DevTool {
    let id = "bezier-curve-visualizer"
    let name = "Bezier Curve Visualizer"
    let category = DevToolCategory.uiDesign
    let icon = "point.topleft.down.curvedto.point.bottomright.up"
    let description = "Interactive cubic Bezier curve editor"

    func render() -> some View {
        BezierCurveVisualizerView()
    }
}

struct BezierCurveVisualizerView: View {
    @StateObject private var viewModel = BezierCurveVisualizerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Bezier Curve Visualizer",
                description: "Interactively adjust control points to design custom cubic Bezier paths for animations or shapes.",
                icon: "point.topleft.down.curvedto.point.bottomright.up"
            )
            .padding()

            VStack {
                BezierCanvas(points: $viewModel.points)
                    .frame(height: 300)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding()

                Form {
                    Section("SwiftUI Code") {
                        Text(viewModel.codeSnippet)
                            .font(.system(.caption2, design: .monospaced))
                            .padding()
                            .background(Color.secondary.opacity(0.1))

                        ExportPanel(content: viewModel.codeSnippet, filename: "bezier_path.swift")
                    }
                }
            }
        }
    }
}

struct BezierCanvas: View {
    @Binding var points: [CGPoint]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Path
                Path { path in
                    path.move(to: points[0])
                    path.addCurve(to: points[3], control1: points[1], control2: points[2])
                }
                .stroke(Color.accentColor, lineWidth: 3)

                // Control lines
                Path { path in
                    path.move(to: points[0])
                    path.addLine(to: points[1])
                    path.move(to: points[3])
                    path.addLine(to: points[2])
                }
                .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))

                // Points
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index == 1 || index == 2 ? Color.orange : Color.blue)
                        .frame(width: 12, height: 12)
                        .position(points[index])
                        .gesture(DragGesture().onChanged { value in
                            points[index] = value.location
                        })
                }
            }
        }
    }
}

class BezierCurveVisualizerViewModel: ObservableObject {
    @Published var points: [CGPoint] = [
        CGPoint(x: 50, y: 250),
        CGPoint(x: 100, y: 50),
        CGPoint(x: 200, y: 50),
        CGPoint(x: 250, y: 250)
    ]

    var codeSnippet: String {
        "path.move(to: CGPoint(x: \(Int(points[0].x)), y: \(Int(points[0].y))))\n" +
        "path.addCurve(to: CGPoint(x: \(Int(points[3].x)), y: \(Int(points[3].y))),\n" +
        "              control1: CGPoint(x: \(Int(points[1].x)), y: \(Int(points[1].y))),\n" +
        "              control2: CGPoint(x: \(Int(points[2].x)), y: \(Int(points[2].y))))"
    }
}
