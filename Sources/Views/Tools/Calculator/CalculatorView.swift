import SwiftUI

struct CalculatorView: View {
    @StateObject private var backend = CalculatorBackend()

    let buttons = [
        ["C", "√", "%", "/"],
        ["7", "8", "9", "*"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["±", "0", ".", "="]
    ]

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Text(backend.display)
                .font(.system(size: 64, weight: .light, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)

            VStack(spacing: 12) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            Button(action: {
                                self.buttonPressed(button)
                            }) {
                                Text(button)
                                    .font(.title)
                                    .bold()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .background(self.buttonColor(button))
                                    .foregroundColor(self.textColor(button))
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Calculator")
    }

    private func buttonPressed(_ button: String) {
        if let _ = Int(button) {
            backend.inputDigit(button)
        } else {
            switch button {
            case "+": backend.setOperation(.add)
            case "-": backend.setOperation(.subtract)
            case "*": backend.setOperation(.multiply)
            case "/": backend.setOperation(.divide)
            case "=": backend.calculate()
            case "C": backend.clear()
            case "√": backend.squareRoot()
            case "%": backend.percentage()
            case "±": backend.negate()
            case ".": backend.inputDecimal()
            default: break
            }
        }
    }

    private func buttonColor(_ button: String) -> Color {
        if ["+", "-", "*", "/", "="].contains(button) {
            return .orange
        } else if ["C", "√", "%", "±"].contains(button) {
            return Color(.systemGray4)
        }
        return Color(.systemGray5)
    }

    private func textColor(_ button: String) -> Color {
        if ["+", "-", "*", "/", "="].contains(button) {
            return .white
        }
        return .primary
    }
}

struct CalculatorTool: Tool {
    let name = "Calculator"
    let icon = "plus.forwardslash.minus"
    let category = ToolCategory.general
    let complexity = ToolComplexity.basic
    let description = "Advanced arithmetic with roots and percentages"
    let requiresAPI = false
    var view: AnyView { AnyView(CalculatorView()) }
}
