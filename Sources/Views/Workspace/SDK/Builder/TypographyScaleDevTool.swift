import SwiftUI

struct TypographyScaleDevTool: DevTool {
    let id = "typography-scale"
    let name = "Typography Scale"
    let category = DevToolCategory.uiDesign
    let icon = "textformat.size"
    let description = "Generate and preview typographic scales"

    func render() -> some View {
        TypographyScaleView()
    }
}

struct TypographyScaleView: View {
    @StateObject private var viewModel = TypographyScaleViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Typography Scale",
                description: "Design harmonious font size hierarchies using musical scales like the Golden Ratio or Major Third.",
                icon: "textformat.size"
            )
            .padding()

            Form {
                Section("Configuration") {
                    TextField("Base Size (pt)", text: $viewModel.baseSize)
                        .keyboardType(.numberPad)

                    Picker("Scale Ratio", selection: $viewModel.scaleRatio) {
                        Text("Minor Second (1.067)").tag(1.067)
                        Text("Major Third (1.250)").tag(1.25)
                        Text("Perfect Fourth (1.333)").tag(1.333)
                        Text("Golden Ratio (1.618)").tag(1.618)
                    }
                }

                Section("Scale Preview") {
                    ForEach(viewModel.scaleItems) { item in
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading) {
                                Text(item.label).font(.caption2).foregroundStyle(.secondary)
                                Text("Sample Text")
                                    .font(.system(size: item.size))
                            }
                            Spacer()
                            Text("\(Int(item.size))pt")
                                .font(.caption.monospaced())
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct ScaleItem: Identifiable {
    let id = UUID()
    let label: String
    let size: CGFloat
}

class TypographyScaleViewModel: ObservableObject {
    @Published var baseSize = "16"
    @Published var scaleRatio = 1.25

    var scaleItems: [ScaleItem] {
        guard let base = Double(baseSize) else { return [] }
        var items: [ScaleItem] = []

        // H1 to H4
        for i in (1...4).reversed() {
            let size = base * pow(scaleRatio, Double(i))
            items.append(ScaleItem(label: "Heading \(5-i)", size: CGFloat(size)))
        }

        items.append(ScaleItem(label: "Body", size: CGFloat(base)))
        items.append(ScaleItem(label: "Small", size: CGFloat(base / scaleRatio)))

        return items
    }
}
