import SwiftUI

struct NumberFormatterDevTool: DevTool {
    let id = "number-formatter"
    let name = "Number Formatter"
    let category = DevToolCategory.data
    let icon = "number"
    let description = "Format numbers (Currency, Decimal, etc.)"

    func render() -> some View {
        NumberFormatterView()
    }
}

struct NumberFormatterView: View {
    @StateObject private var viewModel = NumberFormatterViewModel()

    var body: some View {
        Form {
            Section("Input Number") {
                TextField("1234.56", text: $viewModel.inputText)
                    .keyboardType(.decimalPad)
            }

            Section("Formats") {
                LabeledContent("Decimal", value: viewModel.decimalFormatted)
                LabeledContent("Currency (USD)", value: viewModel.currencyFormatted)
                LabeledContent("Percent", value: viewModel.percentFormatted)
                LabeledContent("Scientific", value: viewModel.scientificFormatted)
            }
        }
    }
}

class NumberFormatterViewModel: ObservableObject {
    @Published var inputText = "1234.56"

    private var number: Double {
        Double(inputText) ?? 0
    }

    var decimalFormatted: String {
        let formatter = Foundation.NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "Error"
    }

    var currencyFormatted: String {
        let formatter = Foundation.NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: number)) ?? "Error"
    }

    var percentFormatted: String {
        let formatter = Foundation.NumberFormatter()
        formatter.numberStyle = .percent
        return formatter.string(from: NSNumber(value: number)) ?? "Error"
    }

    var scientificFormatted: String {
        let formatter = Foundation.NumberFormatter()
        formatter.numberStyle = .scientific
        return formatter.string(from: NSNumber(value: number)) ?? "Error"
    }
}
