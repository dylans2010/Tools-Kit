import SwiftUI

struct ShadowGeneratorTool: DevTool {
    let id = UUID()
    let name = "Shadow Generator"
    let category: DevToolCategory = .uiDesign
    let icon = "square.on.square"
    let description = "Generate and preview shadow configurations"
    func render() -> some View { ShadowGeneratorDevToolView() }
}

struct ShadowGeneratorDevToolView: View {
    @State private var radius: Double = 10
    @State private var xOffset: Double = 0
    @State private var yOffset: Double = 4
    @State private var opacity: Double = 0.3

    var body: some View {
        Form {
            Section("Preview") {
                ZStack {
                    Color(.systemGray6)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 200, height: 100)
                        .shadow(color: .black.opacity(opacity), radius: radius, x: xOffset, y: yOffset)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Section("Configuration") {
                LabeledContent("Radius: \(Int(radius))") { Slider(value: $radius, in: 0...50) }
                LabeledContent("X: \(Int(xOffset))") { Slider(value: $xOffset, in: -30...30) }
                LabeledContent("Y: \(Int(yOffset))") { Slider(value: $yOffset, in: -30...30) }
                LabeledContent("Opacity: \(String(format: "%.1f", opacity))") { Slider(value: $opacity, in: 0...1) }
            }
            Section("SwiftUI Code") {
                Text(".shadow(color: .black.opacity(\(String(format: "%.1f", opacity))), radius: \(Int(radius)), x: \(Int(xOffset)), y: \(Int(yOffset)))")
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Shadow Generator")
    }
}
