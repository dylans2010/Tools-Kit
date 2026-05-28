import SwiftUI

struct ShadowGeneratorDevTool: DevTool {
    let id = "shadow-generator"
    let name = "Shadow Generator"
    let category = DevToolCategory.uiDesign
    let icon = "sun.max"
    let description = "Live shadow design and code export"

    func render() -> some View {
        ShadowGeneratorView()
    }
}

struct ShadowGeneratorView: View {
    @StateObject private var viewModel = ShadowGeneratorViewModel()

    var body: some View {
        Form {
            Section(header: Text("Preview")) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: 150, height: 100)
                    .shadow(
                        color: viewModel.shadowColor.opacity(viewModel.opacity),
                        radius: viewModel.radius,
                        x: viewModel.offsetX,
                        y: viewModel.offsetY
                    )
                    .padding(40)
                    .frame(maxWidth: .infinity)
            }

            Section(header: Text("Parameters")) {
                Slider(value: $viewModel.radius, in: 0...50) { Text("Radius") }
                Slider(value: $viewModel.offsetX, in: -50...50) { Text("X Offset") }
                Slider(value: $viewModel.offsetY, in: -50...50) { Text("Y Offset") }
                Slider(value: $viewModel.opacity, in: 0...1) { Text("Opacity") }
                ColorPicker("Shadow Color", selection: $viewModel.shadowColor)
            }

            Section(header: Text("SwiftUI Code")) {
                Text(viewModel.codeSnippet)
                    .font(.system(.caption2, design: .monospaced))
                    .padding()
                    .background(Color.secondary.opacity(0.1))
            }
        }
    }
}

class ShadowGeneratorViewModel: ObservableObject {
    @Published var radius: CGFloat = 10
    @Published var offsetX: CGFloat = 0
    @Published var offsetY: CGFloat = 5
    @Published var opacity: Double = 0.3
    @Published var shadowColor: Color = .black

    var codeSnippet: String {
        let comp = shadowColor.getComponents()
        return ".shadow(\n  color: Color(red: \(String(format: "%.2f", comp.r)), green: \(String(format: "%.2f", comp.g)), blue: \(String(format: "%.2f", comp.b))).opacity(\(String(format: "%.2f", opacity))),\n  radius: \(Int(radius)),\n  x: \(Int(offsetX)),\n  y: \(Int(offsetY))\n)"
    }
}

#Preview {
    ShadowGeneratorView()
}
