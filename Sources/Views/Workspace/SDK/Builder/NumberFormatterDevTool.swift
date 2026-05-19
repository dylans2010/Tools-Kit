import SwiftUI

struct NumberFormatterDevTool: DevTool {
    let id = "number-formatter"
    let name = "Number Formatter"
    let category = DevToolCategory.data
    let icon = "number.circle"
    let description = "Format numbers into currency, percent, or scientific notation"

    func render() -> some View {
        NumberFormatterView()
    }
}

struct NumberFormatterView: View {
    @StateObject private var viewModel = NumberFormatterViewModel()

    var body: some View {
        Form {
            Section("Input Number") {
                TextField("12345.67", text: $viewModel.input)
                    .keyboardType(.decimalPad)
            }

            Section("Configuration") {
                Picker("Style", selection: $viewModel.style) {
                    Text("Decimal").tag(NumberFormatter.Style.decimal)
                    Text("Currency").tag(NumberFormatter.Style.currency)
                    Text("Percent").tag(NumberFormatter.Style.percent)
                    Text("Scientific").tag(NumberFormatter.Style.scientific)
                    Text("Spell Out").tag(NumberFormatter.Style.spellOut)
                }

                TextField("Locale (e.g. en_US, fr_FR)", text: $viewModel.localeIdentifier)
            }

            Section("Output") {
                Text(viewModel.formattedNumber)
                    .font(.title2.bold())
                    .textSelection(.enabled)
            }
        }
    }
}

class NumberFormatterViewModel: ObservableObject {
    @Published var input = "12345.67"
    @Published var style = NumberFormatter.Style.decimal
    @Published var localeIdentifier = Locale.current.identifier

    var formattedNumber: String {
        guard let num = Double(input) else { return "Invalid Number" }
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = Locale(identifier: localeIdentifier)
        return formatter.string(from: NSNumber(value: num)) ?? "Error"
    }
}

#Preview {
    NumberFormatterView()
}
