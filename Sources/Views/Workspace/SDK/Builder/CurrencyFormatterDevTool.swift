import SwiftUI

struct CurrencyFormatterDevTool: DevTool {
    let id = "currency-formatter"
    let name = "Currency Formatter"
    let category: DevToolCategory = .data
    let icon = "dollarsign.circle"
    let description = "Format numbers as currency for different regions"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "1234.56, USD") { input in
            let parts = input.components(separatedBy: ",")
            let amount = Double(parts[0].trimmingCharacters(in: .whitespaces)) ?? 0
            let code = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces).uppercased() : "USD"
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = code
            return formatter.string(from: NSNumber(value: amount)) ?? "Error"
        }
    }
}
