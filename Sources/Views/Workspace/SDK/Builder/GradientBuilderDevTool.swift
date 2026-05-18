import SwiftUI

struct GradientBuilderDevTool: DevTool {
    let id = "gradient-builder"
    let name = "Gradient Builder"
    let category = DevToolCategory.uiDesign
    let icon = "linear.gradient"
    let description = "Create and preview gradients"

    func render() -> some View {
        GradientBuilderView()
    }
}

struct GradientBuilderView: View {
    @StateObject private var viewModel = GradientBuilderViewModel()

    var body: some View {
        Form {
            Section("Colors") {
                ColorPicker("Start Color", selection: $viewModel.startColor)
                ColorPicker("End Color", selection: $viewModel.endColor)
            }

            Section("Preview") {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(gradient: Gradient(colors: [viewModel.startColor, viewModel.endColor]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 150)
            }

            Section("SwiftUI Code") {
                Text(viewModel.swiftUICode)
                    .font(.monospaced(.caption)())
                    .textSelection(.enabled)
            }
        }
    }
}

class GradientBuilderViewModel: ObservableObject {
    @Published var startColor: Color = .blue
    @Published var endColor: Color = .purple

    var swiftUICode: String {
        "LinearGradient(gradient: Gradient(colors: [\(startColor.description), \(endColor.description)]), startPoint: .topLeading, endPoint: .bottomTrailing)"
    }
}
