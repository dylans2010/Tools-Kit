import SwiftUI

struct LayoutGridPreviewDevTool: DevTool {
    let id = "layout-grid-preview"
    let name = "Layout Grid Preview"
    let category = DevToolCategory.uiDesign
    let icon = "grid"
    let description = "Preview and configure layout grids"

    func render() -> some View {
        LayoutGridPreviewView()
    }
}

struct LayoutGridPreviewView: View {
    @StateObject private var viewModel = LayoutGridPreviewViewModel()

    var body: some View {
        VStack {
            ZStack {
                // Content Mock
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Grid Overlay
                HStack(spacing: viewModel.gutter) {
                    ForEach(0..<viewModel.columns, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.red.opacity(0.1))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, viewModel.margin)
            }
            .frame(height: 200)
            .padding()

            Form {
                Section("Grid Configuration") {
                    Stepper("Columns: \(viewModel.columns)", value: $viewModel.columns, in: 1...12)
                    Slider(value: $viewModel.gutter, in: 0...40) { Text("Gutter") }
                    Slider(value: $viewModel.margin, in: 0...40) { Text("Margin") }
                }

                Section("SwiftUI Snippet") {
                    Text(viewModel.codeSnippet)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                }
            }
        }
    }
}

class LayoutGridPreviewViewModel: ObservableObject {
    @Published var columns = 4
    @Published var gutter: CGFloat = 16
    @Published var margin: CGFloat = 20

    var codeSnippet: String {
        "LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: \(Int(gutter))), count: \(columns)), spacing: \(Int(gutter))) {\n  // Content\n}\n.padding(.horizontal, \(Int(margin)))"
    }
}

#Preview {
    LayoutGridPreviewView()
}
