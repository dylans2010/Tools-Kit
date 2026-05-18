import SwiftUI

struct UnicodeInspectorTool: DevTool {
    let id = UUID()
    let name = "Unicode Inspector"
    let category: DevToolCategory = .inputOutput
    let icon = "character.textbox"
    let description = "Inspect Unicode scalar properties"
    func render() -> some View { UnicodeInspectorDevToolView() }
}

struct UnicodeInspectorDevToolView: View {
    @State private var input = ""
    var body: some View {
        Form {
            Section("Input") {
                TextField("Enter text", text: $input)
            }
            if !input.isEmpty {
                Section("Characters (\(input.count))") {
                    ForEach(Array(input.unicodeScalars.enumerated()), id: \.offset) { _, scalar in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(String(scalar)).font(.title2)
                                Spacer()
                                Text("U+\(String(format: "%04X", scalar.value))")
                                    .font(.system(.caption, design: .monospaced))
                            }
                            HStack {
                                Text("Decimal: \(scalar.value)")
                                Spacer()
                                Text(unicodeCategoryName(scalar.properties.generalCategory))
                            }
                            .font(.caption).foregroundStyle(.secondary)
                            if !scalar.properties.name.isEmpty {
                                Text(scalar.properties.name).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Unicode Inspector")
    }

    private func unicodeCategoryName(_ cat: Unicode.GeneralCategory) -> String {
        switch cat {
        case .uppercaseLetter: return "Uppercase Letter"
        case .lowercaseLetter: return "Lowercase Letter"
        case .decimalNumber: return "Decimal Number"
        case .spaceSeparator: return "Space Separator"
        case .mathSymbol: return "Math Symbol"
        case .currencySymbol: return "Currency Symbol"
        case .dashPunctuation: return "Dash Punctuation"
        default: return "Other"
        }
    }
}
