import SwiftUI

struct NumberFormatterDevTool: DevTool {
    let id = "number-formatter"
    let name = "Number Formatter"
    let category = DevToolCategory.data
    let icon = "number.circle"
    let description = "Format numbers with base conversion and locale support"

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
                    .font(.system(.body, design: .monospaced))
            }

            Section("Formatting Style") {
                Picker("Style", selection: $viewModel.style) {
                    Text("Decimal").tag(NumberFormatter.Style.decimal)
                    Text("Currency").tag(NumberFormatter.Style.currency)
                    Text("Percent").tag(NumberFormatter.Style.percent)
                    Text("Scientific").tag(NumberFormatter.Style.scientific)
                    Text("Spell Out").tag(NumberFormatter.Style.spellOut)
                    Text("Ordinal").tag(NumberFormatter.Style.ordinal)
                }

                TextField("Locale (e.g. en_US, fr_FR)", text: $viewModel.localeIdentifier)
                    .font(.caption)
                    .autocorrectionDisabled()

                Stepper("Decimal Places: \(viewModel.decimalPlaces)", value: $viewModel.decimalPlaces, in: 0...10)
                Toggle("Use Grouping Separator", isOn: $viewModel.useGrouping)
            }

            Section("Formatted Output") {
                Text(viewModel.formattedNumber)
                    .font(.title2.bold())
                    .textSelection(.enabled)

                Button {
                    UIPasteboard.general.string = viewModel.formattedNumber
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered).controlSize(.small)
            }

            Section("Base Conversions") {
                if let intValue = Int(viewModel.input) {
                    LabeledContent("Binary", value: String(intValue, radix: 2))
                    LabeledContent("Octal", value: String(intValue, radix: 8))
                    LabeledContent("Hex", value: "0x" + String(intValue, radix: 16, uppercase: true))
                } else {
                    Text("Enter an integer for base conversions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Common Locales") {
                ForEach(viewModel.commonLocales, id: \.id) { locale in
                    HStack {
                        Text(locale.name)
                            .font(.caption)
                        Spacer()
                        Text(locale.formatted)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Number Info") {
                if let num = Double(viewModel.input) {
                    LabeledContent("Is Integer", value: num.truncatingRemainder(dividingBy: 1) == 0 ? "Yes" : "No")
                    LabeledContent("Is Negative", value: num < 0 ? "Yes" : "No")
                    LabeledContent("Absolute Value", value: String(format: "%g", abs(num)))
                    LabeledContent("Byte Size", value: viewModel.formatBytes(num))
                }
            }
        }
    }
}

struct LocaleFormat: Identifiable {
    let id = UUID()
    let name: String
    let formatted: String
}

class NumberFormatterViewModel: ObservableObject {
    @Published var input = "12345.67"
    @Published var style = NumberFormatter.Style.decimal
    @Published var localeIdentifier = Locale.current.identifier
    @Published var decimalPlaces = 2
    @Published var useGrouping = true

    var formattedNumber: String {
        guard let num = Double(input) else { return "Invalid Number" }
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = style == .decimal ? 0 : decimalPlaces
        formatter.usesGroupingSeparator = useGrouping
        return formatter.string(from: NSNumber(value: num)) ?? "Error"
    }

    var commonLocales: [LocaleFormat] {
        guard let num = Double(input) else { return [] }
        let locales = ["en_US", "en_GB", "fr_FR", "de_DE", "ja_JP", "zh_CN", "pt_BR", "ar_SA"]
        return locales.map { id in
            let formatter = NumberFormatter()
            formatter.numberStyle = style
            formatter.locale = Locale(identifier: id)
            formatter.maximumFractionDigits = decimalPlaces
            let formatted = formatter.string(from: NSNumber(value: num)) ?? ""
            return LocaleFormat(name: id, formatted: formatted)
        }
    }

    func formatBytes(_ num: Double) -> String {
        let absNum = abs(num)
        if absNum >= 1_000_000_000 { return String(format: "%.2f GB", absNum / 1_000_000_000) }
        if absNum >= 1_000_000 { return String(format: "%.2f MB", absNum / 1_000_000) }
        if absNum >= 1_000 { return String(format: "%.2f KB", absNum / 1_000) }
        return String(format: "%.0f B", absNum)
    }
}

#Preview {
    NumberFormatterView()
}
