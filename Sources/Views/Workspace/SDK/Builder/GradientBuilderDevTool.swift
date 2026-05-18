import SwiftUI

struct GradientBuilderDevTool: DevTool {
    let id = "gradient-builder"
    let name = "Gradient Builder"
    let category = DevToolCategory.uiDesign
    let icon = "lineargradient"
    let description = "Create and export SwiftUI gradients"

    func render() -> some View {
        GradientBuilderView()
    }
}

struct GradientBuilderView: View {
    @StateObject private var viewModel = GradientBuilderViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Gradient Builder",
                description: "Design linear gradients with multiple color stops and export the SwiftUI code.",
                icon: "lineargradient"
            )
            .padding()

            Form {
                Section("Gradient Preview") {
                    LinearGradient(
                        gradient: Gradient(colors: viewModel.colors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                    .cornerRadius(12)
                }

                Section("Colors") {
                    ForEach(0..<viewModel.colors.count, id: \.self) { index in
                        ColorPicker("Color \(index + 1)", selection: $viewModel.colors[index])
                    }
                    .onDelete { viewModel.colors.remove(atOffsets: $0) }

                    if viewModel.colors.count < 5 {
                        Button("Add Color") { viewModel.colors.append(.gray) }
                    }
                }

                Section("SwiftUI Code") {
                    Text(viewModel.codeSnippet)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .background(Color.secondary.opacity(0.1))

                    ExportPanel(content: viewModel.codeSnippet, filename: "gradient.swift")
                }
            }
        }
    }
}

class GradientBuilderViewModel: ObservableObject {
    @Published var colors: [Color] = [.blue, .purple]

    var codeSnippet: String {
        let colorStrings = colors.map { c in
            let comp = c.getComponents()
            return "Color(red: \(String(format: "%.2f", comp.r)), green: \(String(format: "%.2f", comp.g)), blue: \(String(format: "%.2f", comp.b)))"
        }
        return "LinearGradient(\n  gradient: Gradient(colors: [\n    \(colorStrings.joined(separator: ",\n    "))\n  ]),\n  startPoint: .topLeading,\n  endPoint: .bottomTrailing\n)"
    }
}
