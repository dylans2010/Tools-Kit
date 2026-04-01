import Foundation

class CurrencyConverterBackend: ObservableObject {
    @Published var amount = "1.0"
    @Published var fromCurrency = "USD"
    @Published var toCurrency = "EUR"
    @Published var result = "0.0"

    let rates: [String: Double] = [
        "USD": 1.0, "EUR": 0.92, "GBP": 0.79, "JPY": 151.45, "CAD": 1.36, "AUD": 1.53, "CHF": 0.90
    ]

    func convert() {
        guard let amountValue = Double(amount) else { return }
        let fromRate = rates[fromCurrency] ?? 1.0
        let toRate = rates[toCurrency] ?? 1.0
        let converted = amountValue / fromRate * toRate
        result = String(format: "%.2f", converted)
    }
}
