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
        Form {
            Section(header: Text("Gradient Preview")) {
                LinearGradient(
                    gradient: Gradient(colors: viewModel.colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)
                .cornerRadius(12)
            }

            Section(header: Text("Colors")) {
                ForEach($viewModel.colors, id: \.self) { $color in
                    ColorPicker("Color", selection: $color)
                }
                .onDelete { viewModel.colors.remove(atOffsets: $0) }

                if viewModel.colors.count < 5 {
                    Button("Add Color") { viewModel.colors.append(.gray) }
                }
            }

            Section(header: Text("SwiftUI Code")) {
                Text(viewModel.codeSnippet)
                    .font(.system(.caption2, design: .monospaced))
                    .padding()
                    .background(Color.secondary.opacity(0.1))

                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.codeSnippet
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("gradient.swift")
                        try? viewModel.codeSnippet.write(to: fileURL, atomically: true, encoding: .utf8)
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
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

#Preview {
    GradientBuilderView()
}
