import SwiftUI

struct ContrastCheckerDevTool: DevTool {
    let id = "contrast-checker"
    let name = "Contrast Checker"
    let category = DevToolCategory.uiDesign
    let icon = "circle.lefthalf.filled"
    let description = "Validate color contrast for accessibility"

    func render() -> some View {
        ContrastCheckerView()
    }
}

struct ContrastCheckerView: View {
    @StateObject private var viewModel = ContrastCheckerViewModel()

    var body: some View {
        List {
            Section("Color Pair") {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        VStack {
                            ColorPicker("", selection: $viewModel.foregroundColor)
                                .labelsHidden()
                                .scaleEffect(1.5)
                            Text("Text").font(.caption2).foregroundStyle(.secondary)
                        }

                        Image(systemName: "arrow.left.and.right").foregroundStyle(.tertiary)

                        VStack {
                            ColorPicker("", selection: $viewModel.backgroundColor)
                                .labelsHidden()
                                .scaleEffect(1.5)
                            Text("Background").font(.caption2).foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            let temp = viewModel.foregroundColor
                            viewModel.foregroundColor = viewModel.backgroundColor
                            viewModel.backgroundColor = temp
                        } label: {
                            Image(systemName: "rectangle.2.swap")
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section("WCAG 2.1 Compliance") {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Contrast Ratio").font(.caption2.bold()).foregroundStyle(.secondary).textCase(.uppercase)
                            Text("\(String(format: "%.2f", viewModel.contrastRatio)):1")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                        }
                        Spacer()
                        complianceBadge
                    }

                    VStack(spacing: 12) {
                        ComplianceRow(label: "Normal Text (AA)", score: 4.5, current: viewModel.contrastRatio)
                        ComplianceRow(label: "Large Text (AA)", score: 3.0, current: viewModel.contrastRatio)
                        ComplianceRow(label: "Normal Text (AAA)", score: 7.0, current: viewModel.contrastRatio)
                        ComplianceRow(label: "Large Text (AAA)", score: 4.5, current: viewModel.contrastRatio)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Preview") {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Headline Text")
                            .font(.title.bold())
                        Text("This is how your text looks with the selected background. Ensuring accessibility is key for modern app development.")
                            .font(.subheadline)
                    }
                    .foregroundStyle(viewModel.foregroundColor)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(viewModel.backgroundColor)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                }
                .padding(.vertical, 4)
            }

            Section("Suggestions") {
                Button("Optimize for AA") { viewModel.optimize(target: 4.5) }
                Button("Optimize for AAA") { viewModel.optimize(target: 7.0) }
            }
        }
        .navigationTitle("Contrast")
    }

    private var complianceBadge: some View {
        Text(viewModel.contrastRatio >= 4.5 ? "PASS" : "FAIL")
            .font(.system(size: 14, weight: .black))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(.white)
            .background(viewModel.contrastRatio >= 4.5 ? Color.green : Color.red, in: Capsule())
    }
}

struct ComplianceRow: View {
    let label: String
    let score: Double
    let current: Double

    var body: some View {
        HStack {
            Text(label).font(.caption)
            Spacer()
            Text("\(score):1").font(.caption.monospaced()).foregroundStyle(.secondary)
            Image(systemName: current >= score ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(current >= score ? .green : .red)
        }
    }
}

class ContrastCheckerViewModel: ObservableObject {
    @Published var backgroundColor: Color = .white
    @Published var foregroundColor: Color = .black

    func optimize(target: Double) {
        // Simple logic to darken foreground if fail
        // In real app, would use HSL adjustments
        foregroundColor = .black
    }

    var contrastRatio: Double {
        let l1 = luminance(color: foregroundColor)
        let l2 = luminance(color: backgroundColor)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    private func luminance(color: Color) -> Double {
        let c = color.getComponents()
        func adjust(_ v: CGFloat) -> Double {
            let d = Double(v)
            return d <= 0.03928 ? d / 12.92 : pow((d + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * adjust(c.r) + 0.7152 * adjust(c.g) + 0.0722 * adjust(c.b)
    }
}

#Preview {
    ContrastCheckerView()
}
