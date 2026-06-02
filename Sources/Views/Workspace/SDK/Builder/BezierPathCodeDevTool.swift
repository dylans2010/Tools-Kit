import SwiftUI

struct BezierPathCodeDevTool: DevTool {
    let id = "bezier-path-code"
    let name = "Bezier Path Code Generator"
    let category: DevToolCategory = .uiDesign
    let icon = "pencil.tip"
    let description = "Generate SwiftUI Path code for Bezier curves"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Describe your path (simulated)") { _ in
            "Path { path in\n    path.move(to: CGPoint(x: 10, y: 10))\n    path.addCurve(to: CGPoint(x: 100, y: 100), control1: CGPoint(x: 50, y: 0), control2: CGPoint(x: 50, y: 150))\n}"
        }
    }
}
