import SwiftUI

struct ContrastCheckerDevTool: DevTool {
    let id = "contrast-checker"
    let name = "Contrast Checker"
    let category = DevToolCategory.uiDesign
    let icon = "circle.lefthalf.filled"
    let description = "Check color contrast ratio (WCAG)"

    func render() -> some View {
        ContrastCheckerView()
    }
}

struct ContrastCheckerView: View {
    @StateObject private var viewModel = ContrastCheckerViewModel()

    var body: some View {
        Form {
            Section("Colors") {
                ColorPicker("Background", selection: $viewModel.backgroundColor)
                ColorPicker("Foreground", selection: $viewModel.foregroundColor)
            }

            Section("Result") {
                HStack {
                    Text("Ratio")
                    Spacer()
                    Text(String(format: "%.2f:1", viewModel.ratio))
                        .font(.headline.monospaced())
                }

                LabeledContent("WCAG AA", value: viewModel.ratio >= 4.5 ? "Pass" : "Fail")
                    .foregroundStyle(viewModel.ratio >= 4.5 ? .green : .red)

                LabeledContent("WCAG AAA", value: viewModel.ratio >= 7.0 ? "Pass" : "Fail")
                    .foregroundStyle(viewModel.ratio >= 7.0 ? .green : .red)
            }

            Section("Preview") {
                ZStack {
                    viewModel.backgroundColor
                    Text("Sample Text")
                        .foregroundStyle(viewModel.foregroundColor)
                        .font(.headline)
                }
                .frame(height: 60)
                .cornerRadius(8)
            }
        }
    }
}

class ContrastCheckerViewModel: ObservableObject {
    @Published var backgroundColor: Color = .white
    @Published var foregroundColor: Color = .black

    var ratio: Double {
        let lum1 = backgroundColor.getLuminance()
        let lum2 = foregroundColor.getLuminance()
        let l1 = max(lum1, lum2)
        let l2 = min(lum1, lum2)
        return (l1 + 0.05) / (l2 + 0.05)
    }
}

extension Color {
    func getLuminance() -> Double {
        let components = self.getComponents()
        func adjust(_ val: CGFloat) -> Double {
            let v = Double(val)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * adjust(components.r) + 0.7152 * adjust(components.g) + 0.0722 * adjust(components.b)
    }
}
