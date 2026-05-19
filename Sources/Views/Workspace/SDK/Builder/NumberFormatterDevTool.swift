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
        List {
            Section("Input") {
                HStack {
                    Image(systemName: "number").foregroundStyle(.secondary)
                    TextField("Enter value", text: $viewModel.input)
                        .keyboardType(.decimalPad)
                        .font(.title3.bold())
                }

                Slider(value: Binding(get: { Double(viewModel.input) ?? 0 }, set: { viewModel.input = String(format: "%.2f", $0) }), in: 0...1000000)
            }

            Section("Configuration") {
                Picker("Format Style", selection: $viewModel.style) {
                    Text("Decimal").tag(NumberFormatter.Style.decimal)
                    Text("Currency").tag(NumberFormatter.Style.currency)
                    Text("Percent").tag(NumberFormatter.Style.percent)
                    Text("Scientific").tag(NumberFormatter.Style.scientific)
                    Text("Spell Out").tag(NumberFormatter.Style.spellOut)
                    Text("Ordinal").tag(NumberFormatter.Style.ordinal)
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Locale")
                    Spacer()
                    TextField("en_US", text: $viewModel.localeIdentifier)
                        .multilineTextAlignment(.trailing)
                        .font(.caption.monospaced())
                }
            }

            Section("Formatted Output") {
                VStack(spacing: 16) {
                    Text(viewModel.formattedNumber)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(.blue.gradient)
                        .textSelection(.enabled)

                    HStack {
                        Button { UIPasteboard.general.string = viewModel.formattedNumber } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }

                        Spacer()

                        Button("Reset") {
                            viewModel.input = "12345.67"
                            viewModel.style = .decimal
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.vertical)
            }

            Section("Metadata") {
                LabeledContent("Is Number", value: viewModel.isValid ? "Yes" : "No")
                LabeledContent("Binary", value: viewModel.binaryValue)
                    .font(.caption2.monospaced())
            }
        }
        .navigationTitle("Numbers")
    }
}

class NumberFormatterViewModel: ObservableObject {
    @Published var input = "12345.67"
    @Published var style = NumberFormatter.Style.decimal
    @Published var localeIdentifier = "en_US"

    var isValid: Bool { Double(input) != nil }

    var formattedNumber: String {
        guard let num = Double(input) else { return "Invalid" }
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = Locale(identifier: localeIdentifier)
        return formatter.string(from: NSNumber(value: num)) ?? "Error"
    }

    var binaryValue: String {
        guard let num = Int(input) else { return "N/A" }
        return String(num, radix: 2)
    }
}

#Preview {
    NumberFormatterView()
}
