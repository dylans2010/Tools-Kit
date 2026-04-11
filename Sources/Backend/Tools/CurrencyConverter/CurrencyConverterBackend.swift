import Foundation

class CurrencyConverterBackend: ObservableObject {
    @Published var amount = "1.0"
    @Published var fromCurrency = "USD"
    @Published var toCurrency = "EUR"
    @Published var result = "0.0"

    // Expanded static rates (relative to 1 USD) - Example/Static values
    let rates: [String: Double] = [
        "USD": 1.0, "EUR": 0.92, "GBP": 0.79, "JPY": 151.45, "CAD": 1.36,
        "AUD": 1.53, "CHF": 0.90, "CNY": 7.23, "INR": 83.34, "BRL": 5.06,
        "RUB": 92.50, "KRW": 1350.20, "SGD": 1.35, "NZD": 1.66, "MXN": 16.55,
        "HKD": 7.83, "ZAR": 18.70, "TRY": 32.20, "SEK": 10.60, "NOK": 10.70,
        "DKK": 6.85, "AED": 3.67, "SAR": 3.75, "ILS": 3.70, "EGP": 47.50,
        "IDR": 15850.0, "MYR": 4.75, "PHP": 56.40, "THB": 36.60, "VND": 24900.0
    ]

    let names: [String: String] = [
        "USD": "US Dollar", "EUR": "Euro", "GBP": "British Pound", "JPY": "Japanese Yen",
        "CAD": "Canadian Dollar", "AUD": "Australian Dollar", "CHF": "Swiss Franc",
        "CNY": "Chinese Yuan", "INR": "Indian Rupee", "BRL": "Brazilian Real",
        "RUB": "Russian Ruble", "KRW": "South Korean Won", "SGD": "Singapore Dollar",
        "NZD": "New Zealand Dollar", "MXN": "Mexican Peso", "HKD": "Hong Kong Dollar",
        "ZAR": "South African Rand", "TRY": "Turkish Lira", "SEK": "Swedish Krona",
        "NOK": "Norwegian Krone", "DKK": "Danish Krone", "AED": "UAE Dirham",
        "SAR": "Saudi Riyal", "ILS": "Israeli Shekel", "EGP": "Egyptian Pound",
        "IDR": "Indonesian Rupiah", "MYR": "Malaysian Ringgit", "PHP": "Philippine Peso",
        "THB": "Thai Baht", "VND": "Vietnamese Dong"
    ]

    func convert() {
        guard let amountValue = Double(amount) else { return }
        let fromRate = rates[fromCurrency] ?? 1.0
        let toRate = rates[toCurrency] ?? 1.0
        let converted = amountValue / fromRate * toRate
        result = String(format: "%.2f", converted)
    }

    func swap() {
        let temp = fromCurrency
        fromCurrency = toCurrency
        toCurrency = temp
        convert()
    }
}
