import SwiftUI

struct NumberFormatterDevToolImpl: DevTool {
    let id = UUID()
    let name = "Number Formatter"
    let category: DevToolCategory = .data
    let icon = "textformat.123"
    let description = "Format numbers in various styles"
    func render() -> some View { NumberFormatterDevToolView() }
}

struct NumberFormatterDevToolView: View {
    @State private var input = "1234567.89"
    @State private var locale = "en_US"
    private let locales = ["en_US", "de_DE", "fr_FR", "ja_JP", "zh_CN", "ar_SA", "hi_IN", "pt_BR"]

    var body: some View {
        Form {
            Section("Input") {
                TextField("Number", text: $input)
                    .font(.system(.body, design: .monospaced))
                    .keyboardType(.decimalPad)
            }
            Section("Locale") {
                Picker("Locale", selection: $locale) {
                    ForEach(locales, id: \.self) { Text($0).tag($0) }
                }
            }
            if let number = Double(input) {
                Section("Formatted") {
                    LabeledContent("Decimal", value: formatted(number, style: .decimal))
                    LabeledContent("Currency", value: formatted(number, style: .currency))
                    LabeledContent("Percent", value: formatted(number / 100, style: .percent))
                    LabeledContent("Scientific", value: formatted(number, style: .scientific))
                    LabeledContent("Spell Out", value: formatted(number, style: .spellOut))
                }
                Section("Conversions") {
                    LabeledContent("Int", value: "\(Int(number))")
                    LabeledContent("Binary", value: String(Int(number), radix: 2))
                    LabeledContent("Octal", value: String(Int(number), radix: 8))
                    LabeledContent("Hex", value: String(Int(number), radix: 16, uppercase: true))
                }
            }
        }
        .navigationTitle("Number Formatter")
    }
    private func formatted(_ number: Double, style: Foundation.NumberFormatter.Style) -> String {
        let f = Foundation.NumberFormatter()
        f.numberStyle = style
        f.locale = Locale(identifier: locale)
        return f.string(from: NSNumber(value: number)) ?? "N/A"
    }
}
