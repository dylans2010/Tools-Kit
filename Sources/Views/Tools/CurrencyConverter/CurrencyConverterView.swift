import SwiftUI

struct CurrencyConverterView: View {
    @StateObject private var backend = CurrencyConverterBackend()

    var body: some View {
        Form {
            Section(header: Text("Amount")) {
                TextField("Amount", text: $backend.amount)
                    .keyboardType(.decimalPad)
                Picker("From", selection: $backend.fromCurrency) {
                    ForEach(Array(backend.rates.keys), id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
            }

            Section(header: Text("Output")) {
                Picker("To", selection: $backend.toCurrency) {
                    ForEach(Array(backend.rates.keys), id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                Text("\(backend.result) \(backend.toCurrency)")
                    .font(.headline)
            }

            Button("Convert") {
                backend.convert()
            }
        }
        .navigationTitle("Currency Converter")
    }
}

struct CurrencyConverterTool: Tool {
    let name = "Currency Converter"
    let icon = "dollarsign.circle"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Real-time currency exchange rates"

    var view: AnyView {
        AnyView(CurrencyConverterView())
    }
}
