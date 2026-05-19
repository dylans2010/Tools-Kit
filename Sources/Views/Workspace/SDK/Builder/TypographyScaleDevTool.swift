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
    @State private var previewText = "The quick brown fox jumps over the lazy dog"
    @State private var showingCode = false

    var body: some View {
        List {
            Section("System Config") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Base Size")
                        Spacer()
                        TextField("16", text: $viewModel.baseSize)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Text("pt")
                    }

                    Picker("Scale Ratio", selection: $viewModel.scaleRatio) {
                        Text("Minor Second").tag(1.067)
                        Text("Major Second").tag(1.125)
                        Text("Major Third").tag(1.25)
                        Text("Perfect Fourth").tag(1.333)
                        Text("Golden Ratio").tag(1.618)
                    }
                    .pickerStyle(.menu)

                    TextField("Preview Text", text: $previewText)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.vertical, 4)
            }

            Section("Scale Preview") {
                ForEach(viewModel.scaleItems) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.label)
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.blue)
                            Spacer()
                            Text("\(Int(item.size))pt / \(String(format: "%.2f", item.size/16))rem")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Text(previewText)
                            .font(.system(size: item.size))
                            .lineLimit(2)
                    }
                    .padding(.vertical, 8)
                }
            }

            Section("Export") {
                Button {
                    showingCode = true
                } label: {
                    Label("View CSS/SwiftUI Variables", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
        }
        .navigationTitle("Typography")
        .sheet(isPresented: $showingCode) {
            TypographyCodeView(items: viewModel.scaleItems)
        }
    }
}

struct TypographyCodeView: View {
    let items: [ScaleItem]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("SwiftUI Constants") {
                    Text(swiftUICode)
                        .font(.system(size: 10, design: .monospaced))
                        .padding(8)
                        .textSelection(.enabled)
                }

                Section("CSS Variables") {
                    Text(cssCode)
                        .font(.system(size: 10, design: .monospaced))
                        .padding(8)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Type Tokens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }

    private var swiftUICode: String {
        items.map { "static let \($0.label.lowercased().replacingOccurrences(of: " ", with: "")): CGFloat = \(Int($0.size))" }.joined(separator: "\n")
    }

    private var cssCode: String {
        items.map { "--font-size-\($0.label.lowercased().replacingOccurrences(of: " ", with: "-")): \(Int($0.size))px;" }.joined(separator: "\n")
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
            items.append(ScaleItem(label: "Level \(i + 1)", size: CGFloat(size)))
        }

        items.append(ScaleItem(label: "Base (Body)", size: CGFloat(base)))

        let small = base / scaleRatio
        items.append(ScaleItem(label: "Small", size: CGFloat(small)))

        let xsmall = small / scaleRatio
        items.append(ScaleItem(label: "X-Small", size: CGFloat(xsmall)))

        return items
    }
}

#Preview {
    TypographyScaleView()
}
