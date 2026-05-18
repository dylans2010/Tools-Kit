import SwiftUI

struct LayoutGridPreviewDevTool: DevTool {
    let id = "layout-grid-preview"
    let name = "Layout Grid Preview"
    let category = DevToolCategory.uiDesign
    let icon = "square.grid.2x2"
    let description = "Preview common layout grids"

    func render() -> some View {
        LayoutGridPreviewView()
    }
}

struct LayoutGridPreviewView: View {
    @State private var columns = 4.0
    @State private var spacing = 10.0

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: Int(columns)), spacing: spacing) {
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: 80)
                            .overlay(Text("\(i+1)").font(.caption))
                    }
                }
                .padding()
            }

            Form {
                Section("Grid Settings") {
                    HStack {
                        Text("Columns: \(Int(columns))")
                        Slider(value: $columns, in: 1...12, step: 1)
                    }
                    HStack {
                        Text("Spacing: \(Int(spacing))")
                        Slider(value: $spacing, in: 0...40)
                    }
                }
            }
            .frame(height: 200)
        }
    }
}
