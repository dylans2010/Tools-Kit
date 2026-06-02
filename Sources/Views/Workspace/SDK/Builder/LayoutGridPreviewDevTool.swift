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
                // Example UI Layout
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Circle().fill(Color.accentColor.opacity(0.2)).frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Rectangle().fill(Color.accentColor.opacity(0.2)).frame(height: 12).cornerRadius(2)
                            Rectangle().fill(Color.accentColor.opacity(0.1)).frame(width: 100, height: 8).cornerRadius(2)
                        }
                        Spacer()
                    }

                    Rectangle().fill(Color.accentColor.opacity(0.05)).frame(height: 80).cornerRadius(8)

                    HStack(spacing: 12) {
                        ForEach(0..<3) { _ in
                            Rectangle().fill(Color.accentColor.opacity(0.1)).frame(height: 40).cornerRadius(4)
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)

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
                Section(header: Text("Grid Configuration")) {
                    Stepper("Columns: \(viewModel.columns)", value: $viewModel.columns, in: 1...12)
                    Slider(value: $viewModel.gutter, in: 0...40) { Text("Gutter") }
                    Slider(value: $viewModel.margin, in: 0...40) { Text("Margin") }
                }

                Section(header: Text("SwiftUI Snippet")) {
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
