import SwiftUI

struct BezierCurveVisualizerDevTool: DevTool {
    let id = "bezier-curve-visualizer"
    let name = "Bezier Curve Visualizer"
    let category = DevToolCategory.uiDesign
    let icon = "curve.dotted"
    let description = "Visualize Cubic Bezier curves"

    func render() -> some View {
        BezierCurveVisualizerView()
    }
}

struct BezierCurveVisualizerView: View {
    @StateObject private var viewModel = BezierCurveViewModel()

    var body: some View {
        VStack {
            BezierCanvas(p0: viewModel.p0, p1: viewModel.p1, p2: viewModel.p2, p3: viewModel.p3)
                .frame(height: 300)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding()

            Form {
                Section("Control Points") {
                    HStack {
                        Text("P1 X: \(Int(viewModel.p1.x))")
                        Slider(value: $viewModel.p1.x, in: 0...300)
                    }
                    HStack {
                        Text("P1 Y: \(Int(viewModel.p1.y))")
                        Slider(value: $viewModel.p1.y, in: 0...300)
                    }
                    HStack {
                        Text("P2 X: \(Int(viewModel.p2.x))")
                        Slider(value: $viewModel.p2.x, in: 0...300)
                    }
                    HStack {
                        Text("P2 Y: \(Int(viewModel.p2.y))")
                        Slider(value: $viewModel.p2.y, in: 0...300)
                    }
                }
            }
        }
    }
}

struct BezierCanvas: View {
    let p0: CGPoint
    let p1: CGPoint
    let p2: CGPoint
    let p3: CGPoint

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: p0)
            path.addCurve(to: p3, control1: p1, control2: p2)
            context.stroke(path, with: .color(.blue), lineWidth: 3)

            var controlPath = Path()
            controlPath.move(to: p0)
            controlPath.addLine(to: p1)
            controlPath.move(to: p3)
            controlPath.addLine(to: p2)
            context.stroke(controlPath, with: .color(.gray), style: StrokeStyle(lineWidth: 1, dash: [5]))

            context.fill(Path(ellipseIn: CGRect(x: p1.x-4, y: p1.y-4, width: 8, height: 8)), with: .color(.red))
            context.fill(Path(ellipseIn: CGRect(x: p2.x-4, y: p2.y-4, width: 8, height: 8)), with: .color(.red))
        }
    }
}

class BezierCurveViewModel: ObservableObject {
    @Published var p0 = CGPoint(x: 50, y: 250)
    @Published var p1 = CGPoint(x: 100, y: 50)
    @Published var p2 = CGPoint(x: 200, y: 50)
    @Published var p3 = CGPoint(x: 250, y: 250)
}
