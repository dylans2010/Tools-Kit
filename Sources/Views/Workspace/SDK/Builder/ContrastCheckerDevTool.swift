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
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Contrast Checker",
                description: "Check text and background color contrast ratios against WCAG accessibility standards.",
                icon: "circle.lefthalf.filled"
            )
            .padding()

            Form {
                Section("Colors") {
                    ColorPicker("Background", selection: $viewModel.backgroundColor)
                    ColorPicker("Foreground (Text)", selection: $viewModel.foregroundColor)
                }

                Section("Preview") {
                    Text("Sample Text")
                        .font(.title.bold())
                        .foregroundStyle(viewModel.foregroundColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.backgroundColor)
                        .cornerRadius(8)
                }

                Section("WCAG Results") {
                    HStack {
                        Text("Ratio: \(String(format: "%.2f", viewModel.contrastRatio)):1")
                            .font(.headline)
                        Spacer()
                        StatusBadge(
                            text: viewModel.contrastRatio >= 4.5 ? "PASS (AA)" : "FAIL (AA)",
                            color: viewModel.contrastRatio >= 4.5 ? .green : .red
                        )
                    }
                }
            }
        }
    }
}

class ContrastCheckerViewModel: ObservableObject {
    @Published var backgroundColor: Color = .white
    @Published var foregroundColor: Color = .black

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
