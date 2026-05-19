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
    @State private var showingCode = false

    var body: some View {
        List {
            Section("Interactive Canvas") {
                VStack(spacing: 16) {
                    BezierCanvas(points: $viewModel.points)
                        .frame(height: 300)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                    HStack {
                        Text("Drag points to reshape the cubic curve").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset") { viewModel.reset() }
                            .font(.caption2.bold())
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Path Metadata") {
                LabeledContent("Point 0 (Start)", value: "\(Int(viewModel.points[0].x)), \(Int(viewModel.points[0].y))")
                LabeledContent("Point 1 (C1)", value: "\(Int(viewModel.points[1].x)), \(Int(viewModel.points[1].y))")
                LabeledContent("Point 2 (C2)", value: "\(Int(viewModel.points[2].x)), \(Int(viewModel.points[2].y))")
                LabeledContent("Point 3 (End)", value: "\(Int(viewModel.points[3].x)), \(Int(viewModel.points[3].y))")
            }

            Section("Code Export") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.codeSnippet)
                        .font(.system(size: 9, design: .monospaced))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    HStack {
                        Button {
                            UIPasteboard.general.string = viewModel.codeSnippet
                        } label: {
                            Label("Copy SwiftUI Path", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Spacer()

                        Button("Share") { viewModel.shareCode() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Bezier Lab")
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
        CGPoint(x: 60, y: 240),
        CGPoint(x: 80, y: 60),
        CGPoint(x: 220, y: 60),
        CGPoint(x: 240, y: 240)
    ]

    func reset() {
        points = [
            CGPoint(x: 60, y: 240),
            CGPoint(x: 80, y: 60),
            CGPoint(x: 220, y: 60),
            CGPoint(x: 240, y: 240)
        ]
    }

    var codeSnippet: String {
        "Path { path in\n" +
        "    path.move(to: CGPoint(x: \(Int(points[0].x)), y: \(Int(points[0].y))))\n" +
        "    path.addCurve(\n" +
        "        to: CGPoint(x: \(Int(points[3].x)), y: \(Int(points[3].y))),\n" +
        "        control1: CGPoint(x: \(Int(points[1].x)), y: \(Int(points[1].y))),\n" +
        "        control2: CGPoint(x: \(Int(points[2].x)), y: \(Int(points[2].y)))\n" +
        "    )\n" +
        "}"
    }

    func shareCode() {
        let av = UIActivityViewController(activityItems: [codeSnippet], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

#Preview {
    BezierCurveVisualizerView()
}
