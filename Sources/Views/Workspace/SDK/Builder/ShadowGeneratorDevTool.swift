import SwiftUI

struct ShadowGeneratorDevTool: DevTool {
    let id = "shadow-generator"
    let name = "Shadow Generator"
    let category = DevToolCategory.uiDesign
    let icon = "shadow"
    let description = "Generate and preview SwiftUI shadows"

    func render() -> some View {
        ShadowGeneratorView()
    }
}

struct ShadowGeneratorView: View {
    @StateObject private var viewModel = ShadowGeneratorViewModel()

    var body: some View {
        Form {
            Section("Properties") {
                HStack {
                    Text("Radius: \(Int(viewModel.radius))")
                    Slider(value: $viewModel.radius, in: 0...50)
                }
                HStack {
                    Text("X Offset: \(Int(viewModel.xOffset))")
                    Slider(value: $viewModel.xOffset, in: -50...50)
                }
                HStack {
                    Text("Y Offset: \(Int(viewModel.yOffset))")
                    Slider(value: $viewModel.yOffset, in: -50...50)
                }
                ColorPicker("Shadow Color", selection: $viewModel.shadowColor)
            }

            Section("Preview") {
                VStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .systemBackground))
                        .frame(width: 100, height: 100)
                        .shadow(color: viewModel.shadowColor, radius: viewModel.radius, x: viewModel.xOffset, y: viewModel.yOffset)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            }

            Section("SwiftUI Code") {
                Text(viewModel.swiftUICode)
                    .font(.monospaced(.caption)())
                    .textSelection(.enabled)
            }
        }
    }
}

class ShadowGeneratorViewModel: ObservableObject {
    @Published var radius: CGFloat = 10
    @Published var xOffset: CGFloat = 0
    @Published var yOffset: CGFloat = 5
    @Published var shadowColor: Color = .black.opacity(0.3)

    var swiftUICode: String {
        ".shadow(color: \(shadowColor.description), radius: \(radius), x: \(xOffset), y: \(yOffset))"
    }
}
