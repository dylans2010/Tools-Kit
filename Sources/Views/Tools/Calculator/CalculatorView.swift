import SwiftUI

struct CalculatorView: View {
    @StateObject private var backend = CalculatorBackend()

    let buttons = [
        ["7", "8", "9", "/"],
        ["4", "5", "6", "*"],
        ["1", "2", "3", "-"],
        ["C", "0", "=", "+"]
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text(backend.display)
                .font(.system(size: 64))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { button in
                        Button(action: {
                            self.buttonPressed(button)
                        }) {
                            Text(button)
                                .font(.title)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(self.buttonColor(button))
                                .foregroundColor(.white)
                                .cornerRadius(12)
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
            default: break
            }
        }
    }

    private func buttonColor(_ button: String) -> Color {
        if ["+", "-", "*", "/", "="].contains(button) {
            return .orange
        } else if button == "C" {
            return .red
        }
        return .gray
    }
}

struct CalculatorTool: Tool {
    let name = "Calculator"
    let icon = "plus.forwardslash.minus"
    let category = ToolCategory.general
    let complexity = ToolComplexity.basic
    let description = "Basic arithmetic operations"
    let requiresAPI = false

    var view: AnyView {
        AnyView(CalculatorView())
    }
}
