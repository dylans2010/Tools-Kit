import SwiftUI

struct ShadowGeneratorDevTool: DevTool {
    let id = "shadow-generator"
    let name = "Shadow Generator"
    let category = DevToolCategory.uiDesign
    let icon = "sun.max"
    let description = "Live shadow design and code export"

    func render() -> some View {
        ShadowGeneratorView()
    }
}

struct ShadowGeneratorView: View {
    @StateObject private var viewModel = ShadowGeneratorViewModel()
    @State private var previewBg: Color = Color(.systemGroupedBackground)

    var body: some View {
        List {
            Section("Live Preview") {
                VStack(spacing: 20) {
                    ZStack {
                        previewBg.ignoresSafeArea()

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))
                            .frame(width: 160, height: 100)
                            .shadow(
                                color: viewModel.shadowColor.opacity(viewModel.opacity),
                                radius: viewModel.radius,
                                x: viewModel.offsetX,
                                y: viewModel.offsetY
                            )
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 1))

                    ColorPicker("Preview Background", selection: $previewBg)
                        .font(.caption)
                }
                .padding(.vertical, 8)
            }

            Section("Adjustments") {
                ShadowSlider(label: "Blur Radius", value: $viewModel.radius, range: 0...60, unit: "pt")
                ShadowSlider(label: "X Offset", value: $viewModel.offsetX, range: -40...40, unit: "pt")
                ShadowSlider(label: "Y Offset", value: $viewModel.offsetY, range: -40...40, unit: "pt")
                ShadowSlider(label: "Opacity", value: $viewModel.opacity, range: 0...1, unit: "%", multiplier: 100)

                ColorPicker("Shadow Color", selection: $viewModel.shadowColor)
                    .font(.subheadline.bold())
            }

            Section("Generated Code") {
                VStack(alignment: .leading, spacing: 12) {
                    CodeBox(title: "SwiftUI", code: viewModel.codeSnippet)
                    CodeBox(title: "CSS Box Shadow", code: viewModel.cssSnippet)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    UIPasteboard.general.string = viewModel.codeSnippet
                } label: {
                    Label("Copy SwiftUI Code", systemImage: "doc.on.doc")
                }
            }
        }
        .navigationTitle("Shadow Lab")
    }
}

struct ShadowSlider: View {
    let label: String
    @Binding var value: CGFloat
    var range: ClosedRange<CGFloat>
    var unit: String
    var multiplier: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption.bold())
                Spacer()
                Text("\(Int(value * multiplier))\(unit)").font(.caption.monospaced()).foregroundStyle(.blue)
            }
            Slider(value: $value, in: range)
        }
        .padding(.vertical, 4)
    }
}

struct CodeBox: View {
    let title: String
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
            Text(code)
                .font(.system(size: 9, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(6)
                .textSelection(.enabled)
        }
    }
}

class ShadowGeneratorViewModel: ObservableObject {
    @Published var radius: CGFloat = 12
    @Published var offsetX: CGFloat = 0
    @Published var offsetY: CGFloat = 4
    @Published var opacity: Double = 0.25
    @Published var shadowColor: Color = .black

    var codeSnippet: String {
        let comp = shadowColor.getComponents()
        return ".shadow(\n    color: Color(red: \(String(format: "%.2f", comp.r)), green: \(String(format: "%.2f", comp.g)), blue: \(String(format: "%.2f", comp.b))).opacity(\(String(format: "%.2f", opacity))),\n    radius: \(Int(radius)),\n    x: \(Int(offsetX)),\n    y: \(Int(offsetY))\n)"
    }

    var cssSnippet: String {
        let comp = shadowColor.getComponents()
        return "box-shadow: \(Int(offsetX))px \(Int(offsetY))px \(Int(radius))px rgba(\(Int(comp.r*255)), \(Int(comp.g*255)), \(Int(comp.b*255)), \(String(format: "%.2f", opacity)));"
    }
}

#Preview {
    ShadowGeneratorView()
}
