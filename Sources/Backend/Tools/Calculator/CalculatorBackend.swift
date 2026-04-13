import Foundation

class CalculatorBackend: ObservableObject {
    @Published var display = "0"
    @Published var history: [CalculationEntry] = []
    private var accumulator: Double? = nil
    private var pendingOperation: Operation? = nil
    private var isEnteringNumber = false

    struct CalculationEntry: Identifiable, Codable {
        let id = UUID()
        let expression: String
        let result: String
    }

    enum Operation: String {
        case add = "+", subtract = "-", multiply = "×", divide = "÷"
    }

    init() {
        loadHistory()
    }

    func inputDigit(_ digit: String) {
        if !isEnteringNumber || display == "0" {
            display = digit
            isEnteringNumber = true
        } else {
            display += digit
        }
    }

    func inputDecimal() {
        if !display.contains(".") {
            display += "."
            isEnteringNumber = true
        }
    }

    func setOperation(_ operation: Operation) {
        if let current = Double(display) {
            if let acc = accumulator, let op = pendingOperation {
                accumulator = perform(op, acc, current)
            } else {
                accumulator = current
            }
            display = format(accumulator!)
        }
        pendingOperation = operation
        isEnteringNumber = false
    }

    func calculate() {
        if let current = Double(display), let acc = accumulator, let op = pendingOperation {
            let result = perform(op, acc, current)
            let expression = "\(format(acc)) \(op.rawValue) \(format(current))"
            let resultStr = format(result)

            let entry = CalculationEntry(expression: expression, result: resultStr)
            history.insert(entry, at: 0)
            if history.count > 50 { history.removeLast() }
            saveHistory()

            display = resultStr
            accumulator = nil
            pendingOperation = nil
            isEnteringNumber = false
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "calculator_history")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "calculator_history"),
           let decoded = try? JSONDecoder().decode([CalculationEntry].self, from: data) {
            history = decoded
        }
    }

    func clearHistory() {
        history = []
        saveHistory()
    }

    func percentage() {
        if let current = Double(display) {
            display = format(current / 100.0)
            isEnteringNumber = false
        }
    }

    func negate() {
        if let current = Double(display) {
            display = format(current * -1.0)
        }
    }

    func squareRoot() {
        if let current = Double(display), current >= 0 {
            display = format(sqrt(current))
            isEnteringNumber = false
        }
    }

    func clear() {
        display = "0"
        accumulator = nil
        pendingOperation = nil
        isEnteringNumber = false
    }

    private func perform(_ op: Operation, _ a: Double, _ b: Double) -> Double {
        switch op {
        case .add: return a + b
        case .subtract: return a - b
        case .multiply: return a * b
        case .divide: return b != 0 ? a / b : 0
        }
    }

    private func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
