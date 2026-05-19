import SwiftUI

struct ASCIIHexConverterDevTool: DevTool {
    let id = "ascii-hex-converter"
    let name = "ASCII / Hex Converter"
    let category = DevToolCategory.encoding
    let icon = "number"
    let description = "Convert between text and hexadecimal"

    func render() -> some View {
        ASCIIHexConverterView()
    }
}

struct ASCIIHexConverterView: View {
    @StateObject private var viewModel = ASCIIHexConverterViewModel()

    var body: some View {
        List {
            Section("Source Text") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.textInput)
                        .frame(height: 100)
                        .font(.system(.subheadline, design: .monospaced))

                    if !viewModel.textInput.isEmpty {
                        Button { viewModel.textInput = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }
            }

            Section("Representations") {
                ConverterRow(label: "Hexadecimal", value: $viewModel.hexInput)
                ConverterRow(label: "Binary", value: $viewModel.binaryInput)
                ConverterRow(label: "Octal", value: $viewModel.octalInput)
                ConverterRow(label: "Decimal (Bytes)", value: $viewModel.decimalInput)
            }

            Section("Configuration") {
                Toggle("Group Bytes (Spaces)", isOn: $viewModel.addSpaces)
                Toggle("Uppercase Output", isOn: $viewModel.isUppercase)
                Toggle("Include C-Style Prefix (0x, 0b)", isOn: $viewModel.addPrefix)
            }

            Section("System Specs") {
                LabeledContent("Encoding", value: "UTF-8 / Unicode")
                LabeledContent("Endianness", value: "Host (Little Endian)")
                LabeledContent("Bit Width", value: "8-bit per unit")
            }
        }
        .navigationTitle("Base Converter")
    }
}

struct ConverterRow: View {
    let label: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.blue).textCase(.uppercase)
            HStack {
                TextField("", text: $value)
                    .font(.system(size: 11, design: .monospaced))
                    .textFieldStyle(.plain)

                Button {
                    UIPasteboard.general.string = value
                } label: {
                    Image(systemName: "doc.on.doc").font(.caption2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

class ASCIIHexConverterViewModel: ObservableObject {
    @Published var textInput = "ToolsKit" {
        didSet { if !lock { updateFromText() } }
    }
    @Published var hexInput = "" {
        didSet { if !lock { updateFromHex() } }
    }
    @Published var binaryInput = ""
    @Published var octalInput = ""
    @Published var decimalInput = ""

    @Published var addSpaces = true { didSet { updateFromText() } }
    @Published var isUppercase = true { didSet { updateFromText() } }
    @Published var addPrefix = false { didSet { updateFromText() } }

    private var lock = false

    init() {
        updateFromText()
    }

    private func updateFromText() {
        lock = true
        defer { lock = false }

        guard let data = textInput.data(using: .utf8) else { return }

        // Hex
        let hexFormat = (addPrefix ? "0x" : "") + (isUppercase ? "%02X" : "%02x")
        hexInput = data.map { String(format: hexFormat, $0) }.joined(separator: addSpaces ? " " : "")

        // Binary
        binaryInput = data.map { byte in
            let b = String(byte, radix: 2)
            let padded = String(repeating: "0", count: 8 - b.count) + b
            return (addPrefix ? "0b" : "") + padded
        }.joined(separator: addSpaces ? " " : "")

        // Octal
        octalInput = data.map { (addPrefix ? "0" : "") + String($0, radix: 8) }.joined(separator: addSpaces ? " " : "")

        // Decimal
        decimalInput = data.map { String($0) }.joined(separator: addSpaces ? ", " : "")
    }

    private func updateFromHex() {
        lock = true
        defer { lock = false }

        let cleaned = hexInput.replacingOccurrences(of: " ", with: "")
                             .replacingOccurrences(of: "0x", with: "")
                             .replacingOccurrences(of: "0X", with: "")

        var data = Data()
        var idx = cleaned.startIndex
        while idx < cleaned.endIndex {
            let next = cleaned.index(idx, offsetBy: 2, limitedBy: cleaned.endIndex) ?? cleaned.endIndex
            if let byte = UInt8(cleaned[idx..<next], radix: 16) {
                data.append(byte)
            }
            idx = next
        }

        if let s = String(data: data, encoding: .utf8) {
            textInput = s
        }
    }
}

#Preview {
    ASCIIHexConverterView()
}
