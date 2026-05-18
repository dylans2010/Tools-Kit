import SwiftUI

struct TypographyScaleDevTool: DevTool {
    let id = "typography-scale"
    let name = "Typography Scale"
    let category = DevToolCategory.uiDesign
    let icon = "textformat.size"
    let description = "Preview different typography scales"

    func render() -> some View {
        TypographyScaleView()
    }
}

struct TypographyScaleView: View {
    @StateObject private var viewModel = TypographyScaleViewModel()

    var body: some View {
        List {
            Section("Scale Settings") {
                HStack {
                    Text("Base Size: \(Int(viewModel.baseSize))")
                    Slider(value: $viewModel.baseSize, in: 12...24)
                }
                Picker("Ratio", selection: $viewModel.ratio) {
                    Text("Minor Second (1.067)").tag(1.067)
                    Text("Major Second (1.125)").tag(1.125)
                    Text("Perfect Fourth (1.333)").tag(1.333)
                    Text("Golden Ratio (1.618)").tag(1.618)
                }
            }

            Section("Preview") {
                ForEach(0..<6) { index in
                    let size = viewModel.calculateSize(for: 5 - index)
                    VStack(alignment: .leading) {
                        Text("Heading \(5 - index)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("The quick brown fox")
                            .font(.system(size: size))
                        Text("\(Int(size))px")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

class TypographyScaleViewModel: ObservableObject {
    @Published var baseSize: CGFloat = 16
    @Published var ratio: Double = 1.333

    func calculateSize(for level: Int) -> CGFloat {
        return baseSize * CGFloat(pow(ratio, Double(level)))
    }
}
