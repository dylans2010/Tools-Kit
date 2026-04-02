import SwiftUI

struct CurrencyConverterView: View {
    @StateObject private var backend = CurrencyConverterBackend()

    var body: some View {
        Form {
            Section(header: Text("Exchange Rate Conversion")) {
                VStack(spacing: 16) {
                    HStack {
                        TextField("Amount", text: $backend.amount)
                            .keyboardType(.decimalPad)
                            .font(.title2.bold())
                            .onChange(of: backend.amount) { _ in backend.convert() }

                        Spacer()

                        Picker("", selection: $backend.fromCurrency) {
                            ForEach(backend.rates.keys.sorted(), id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .onChange(of: backend.fromCurrency) { _ in backend.convert() }
                    }

                    Button(action: backend.swap) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title2)
                    }

                    HStack {
                        Text(backend.result)
                            .font(.title2.bold())
                            .foregroundColor(.blue)

                        Spacer()

                        Picker("", selection: $backend.toCurrency) {
                            ForEach(backend.rates.keys.sorted(), id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .onChange(of: backend.toCurrency) { _ in backend.convert() }
                    }
                }
                .padding(.vertical, 8)
            }

            Section(header: Text("Info")) {
                Text("Note: Rates are approximate and for demonstration purposes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button(action: { UIPasteboard.general.string = backend.result }) {
                    Label("Copy Result", systemImage: "doc.on.doc")
                }
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
    let description = "Fast currency exchange rate conversion (static data)"
    let requiresAPI = false // Changed to false because we're using static rates for now
    var view: AnyView { AnyView(CurrencyConverterView()) }
}
