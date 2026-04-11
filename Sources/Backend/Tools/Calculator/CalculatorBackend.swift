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
        let timestamp = Date()
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

    @Published var expressionInput: String = ""

    func evaluateExpression() {
        guard !expressionInput.isEmpty else { return }
        let expr = expressionInput
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "π", with: String(Double.pi))
            .replacingOccurrences(of: "e", with: String(M_E))

        let parser = MathExpressionParser(expression: expr)
        if let result = parser.parse(), result.isFinite {
            let resultStr = format(result)
            let entry = CalculationEntry(expression: expressionInput, result: resultStr)
            history.insert(entry, at: 0)
            if history.count > 50 { history.removeLast() }
            saveHistory()
            display = resultStr
            isEnteringNumber = false
        } else {
            display = "Error"
        }
    }

    // MARK: - Safe Math Expression Parser (recursive descent, whitelist-only)
    private struct MathExpressionParser {
        let tokens: [Token]
        var pos: Int = 0

        enum Token {
            case number(Double)
            case plus, minus, multiply, divide, power
            case lparen, rparen
        }

        init(expression: String) {
            var ts: [Token] = []
            var i = expression.startIndex
            while i < expression.endIndex {
                let ch = expression[i]
                if ch.isWhitespace { i = expression.index(after: i); continue }
                if ch.isNumber || ch == "." {
                    var numStr = ""
                    while i < expression.endIndex && (expression[i].isNumber || expression[i] == ".") {
                        numStr.append(expression[i])
                        i = expression.index(after: i)
                    }
                    if let v = Double(numStr) { ts.append(.number(v)) }
                    continue
                }
                switch ch {
                case "+": ts.append(.plus)
                case "-": ts.append(.minus)
                case "*": ts.append(.multiply)
                case "/": ts.append(.divide)
                case "^": ts.append(.power)
                case "(": ts.append(.lparen)
                case ")": ts.append(.rparen)
                default: break
                }
                i = expression.index(after: i)
            }
            self.tokens = ts
        }

        mutating func parse() -> Double? {
            let result = parseAddSub()
            return pos == tokens.count ? result : nil
        }

        private mutating func parseAddSub() -> Double? {
            guard var left = parseMulDiv() else { return nil }
            while pos < tokens.count {
                switch tokens[pos] {
                case .plus:  pos += 1; guard let r = parseMulDiv() else { return nil }; left += r
                case .minus: pos += 1; guard let r = parseMulDiv() else { return nil }; left -= r
                default: return left
                }
            }
            return left
        }

        private mutating func parseMulDiv() -> Double? {
            guard var left = parsePower() else { return nil }
            while pos < tokens.count {
                switch tokens[pos] {
                case .multiply: pos += 1; guard let r = parsePower() else { return nil }; left *= r
                case .divide:   pos += 1; guard let r = parsePower() else { return nil }; guard r != 0 else { return nil }; left /= r
                default: return left
                }
            }
            return left
        }

        private mutating func parsePower() -> Double? {
            guard let base = parseUnary() else { return nil }
            if pos < tokens.count, case .power = tokens[pos] {
                pos += 1
                guard let exp = parseUnary() else { return nil }
                return pow(base, exp)
            }
            return base
        }

        private mutating func parseUnary() -> Double? {
            if pos < tokens.count, case .minus = tokens[pos] {
                pos += 1
                guard let v = parsePrimary() else { return nil }
                return -v
            }
            return parsePrimary()
        }

        private mutating func parsePrimary() -> Double? {
            guard pos < tokens.count else { return nil }
            switch tokens[pos] {
            case .number(let v): pos += 1; return v
            case .lparen:
                pos += 1
                guard let v = parseAddSub() else { return nil }
                guard pos < tokens.count, case .rparen = tokens[pos] else { return nil }
                pos += 1
                return v
            default: return nil
            }
        }
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
