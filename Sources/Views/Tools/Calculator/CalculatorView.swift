import SwiftUI

import Charts

struct CalculatorView: View {
    @StateObject private var backend = CalculatorBackend()
    @State private var mode: CalcMode = .standard

    enum CalcMode {
        case standard, scientific, graphing, geometry, history
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                Image(systemName: "plus.forwardslash.minus").tag(CalcMode.standard)
                Image(systemName: "function").tag(CalcMode.scientific)
                Image(systemName: "chart.xyaxis.line").tag(CalcMode.graphing)
                Image(systemName: "shape.fill").tag(CalcMode.geometry)
                Image(systemName: "clock.arrow.circlepath").tag(CalcMode.history)
            }
            .pickerStyle(.segmented)
            .padding()

            switch mode {
            case .standard: StandardCalcView(backend: backend)
            case .scientific: ScientificCalcView(backend: backend)
            case .graphing: GraphingCalcView()
            case .geometry: GeometryCalcView()
            case .history: CalcHistoryView(backend: backend)
            }
        }
        .navigationTitle("Calculator")
    }
}

private struct StandardCalcView: View {
    @ObservedObject var backend: CalculatorBackend

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
            DisplayView(display: backend.display)

            VStack(spacing: 12) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            CalcButton(label: button, color: buttonColor(button), textColor: textColor(button)) {
                                buttonPressed(button)
                            }
                        }
                    }
                }
            }
        }
        .padding()
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
        if ["+", "-", "*", "/", "="].contains(button) { return .orange }
        else if ["C", "√", "%", "±"].contains(button) { return Color(.systemGray4) }
        return Color(.systemGray5)
    }

    private func textColor(_ button: String) -> Color {
        if ["+", "-", "*", "/", "="].contains(button) { return .white }
        return .primary
    }
}

private struct ScientificCalcView: View {
    @ObservedObject var backend: CalculatorBackend

    let buttons = [
        ["sin", "cos", "tan", "log"],
        ["ln", "e", "π", "^"],
        ["(", ")", "!", "√"],
        ["7", "8", "9", "÷"],
        ["4", "5", "6", "×"],
        ["1", "2", "3", "-"],
        ["C", "0", ".", "="]
    ]

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            DisplayView(display: backend.display)

            VStack(spacing: 10) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { button in
                            CalcButton(label: button, color: scientificColor(button), textColor: .primary, size: 45) {
                                // Simplified: only basic ops work for now in scientific too
                                handleScientific(button)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func handleScientific(_ button: String) {
        // Implementation for scientific functions
        if let val = Double(backend.display) {
            switch button {
            case "sin": backend.display = String(format: "%.4f", sin(val * .pi / 180))
            case "cos": backend.display = String(format: "%.4f", cos(val * .pi / 180))
            case "tan": backend.display = String(format: "%.4f", tan(val * .pi / 180))
            case "log": backend.display = String(format: "%.4f", log10(val))
            case "ln": backend.display = String(format: "%.4f", log(val))
            case "π": backend.display = String(format: "%.8f", Double.pi)
            case "e": backend.display = String(format: "%.8f", exp(1.0))
            case "C": backend.clear()
            case "=": backend.calculate()
            default:
                if let _ = Int(button) { backend.inputDigit(button) }
                else if button == "." { backend.inputDecimal() }
            }
        }
    }

    private func scientificColor(_ button: String) -> Color {
        if ["sin", "cos", "tan", "log", "ln", "e", "π", "^", "(", ")", "!", "√"].contains(button) {
            return Color.blue.opacity(0.2)
        }
        return Color(.systemGray5)
    }
}

private struct GraphingCalcView: View {
    @State private var equation = "x^2"

    var body: some View {
        VStack {
            Chart {
                ForEach(-10...10, id: \.self) { x in
                    LineMark(
                        x: .value("X", Double(x)),
                        y: .value("Y", pow(Double(x), 2))
                    )
                }
            }
            .frame(height: 300)
            .padding()

            TextField("Equation (e.g. x^2)", text: $equation)
                .textFieldStyle(.roundedBorder)
                .padding()

            Text("Graphing simple functions relative to X.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct GeometryCalcView: View {
    @State private var radius = ""
    @State private var result = ""

    var body: some View {
        Form {
            Section {
                TextField("Radius", text: $radius)
                    .keyboardType(.decimalPad)
                Button("Calculate") {
                    if let r = Double(radius) {
                        result = String(format: "%.2f", Double.pi * r * r)
                    }
                }
                if !result.isEmpty {
                    Text("Area: \(result)")
                }
            } header: {
                Text("Circle Area")
            } footer: {
                Text("Enter radius to calculate area.")
            }
        }
    }
}

private struct CalcHistoryView: View {
    @ObservedObject var backend: CalculatorBackend

    var body: some View {
        List {
            ForEach(backend.history) { entry in
                VStack(alignment: .leading) {
                    Text(entry.expression)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(entry.result)
                        .font(.headline)
                }
            }
            if backend.history.isEmpty {
                Text("No calculation history yet.")
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            Button("Clear") { backend.clearHistory() }
        }
    }
}

private struct DisplayView: View {
    let display: String
    var body: some View {
        Text(display)
            .font(.system(size: 64, weight: .light, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
    }
}

private struct CalcButton: View {
    let label: String
    let color: Color
    let textColor: Color
    var size: CGFloat = 60
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity)
                .frame(height: size)
                .background(color)
                .foregroundColor(textColor)
                .cornerRadius(12)
        }
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
