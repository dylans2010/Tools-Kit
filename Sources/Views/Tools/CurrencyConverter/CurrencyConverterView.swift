import SwiftUI

struct CurrencyConverterView: View {
    @StateObject private var backend = CurrencyConverterBackend()

    var body: some View {
        Form {
            Section {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source Amount")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            TextField("Amount", text: $backend.amount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .onChange(of: backend.amount) { _, _ in backend.convert() }

                            Spacer()

                            Picker("From", selection: $backend.fromCurrency) {
                                ForEach(backend.rates.keys.sorted(), id: \.self) { currency in
                                    Text("\(currency) - \(backend.names[currency] ?? "")").tag(currency)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    Button(action: backend.swap) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Converted Amount")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Text(backend.result)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)

                            Spacer()

                            Picker("To", selection: $backend.toCurrency) {
                                ForEach(backend.rates.keys.sorted(), id: \.self) { currency in
                                    Text("\(currency) - \(backend.names[currency] ?? "")").tag(currency)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding(.vertical, 12)
            } header: {
                Text("Quick Convert")
            } footer: {
                Text("Exchange rates are updated periodically and intended for reference only.")
            }

            Section {
                Button(action: { UIPasteboard.general.string = backend.result }) {
                    Label("Copy Result", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("Currency Converter")
    }
}

struct CurrencyConverterTool: Tool, Sendable {
    let name = "Currency Converter"
    let icon = "dollarsign.circle"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Fast currency exchange rate conversion (static data)"
    let requiresAPI = false // Changed to false because we're using static rates for now
    var view: AnyView { AnyView(CurrencyConverterView()) }
}
