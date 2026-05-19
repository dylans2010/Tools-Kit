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
        Form {
            Section("Text (ASCII/UTF-8)") {
                TextEditor(text: $viewModel.textInput)
                    .frame(height: 100)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Hexadecimal") {
                TextEditor(text: $viewModel.hexInput)
                    .frame(height: 100)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Configuration") {
                Toggle("Add Spaces", isOn: $viewModel.addSpaces)
                Toggle("Uppercase Hex", isOn: $viewModel.isUppercase)
            }
        }
    }
}

class ASCIIHexConverterViewModel: ObservableObject {
    @Published var textInput = "" {
        didSet {
            if !isProcessingHex {
                isProcessingText = true
                convertToHex()
                isProcessingText = false
            }
        }
    }
    @Published var hexInput = "" {
        didSet {
            if !isProcessingText {
                isProcessingHex = true
                convertToText()
                isProcessingHex = false
            }
        }
    }

    @Published var addSpaces = true
    @Published var isUppercase = true

    private var isProcessingText = false
    private var isProcessingHex = false

    private func convertToHex() {
        guard let data = textInput.data(using: .utf8) else { return }
        let format = isUppercase ? "%02X" : "%02x"
        let hex = data.map { String(format: format, $0) }.joined(separator: addSpaces ? " " : "")
        hexInput = hex
    }

    private func convertToText() {
        let cleanedHex = hexInput.replacingOccurrences(of: " ", with: "")
                                .replacingOccurrences(of: "0x", with: "")

        var data = Data()
        var startIndex = cleanedHex.startIndex
        while startIndex < cleanedHex.endIndex {
            let endIndex = cleanedHex.index(startIndex, offsetBy: 2, limitedBy: cleanedHex.endIndex) ?? cleanedHex.endIndex
            let hexByte = String(cleanedHex[startIndex..<endIndex])
            if let byte = UInt8(hexByte, radix: 16) {
                data.append(byte)
            }
            startIndex = endIndex
        }

        if let decoded = String(data: data, encoding: .utf8) {
            textInput = decoded
        }
    }
}

#Preview {
    ASCIIHexConverterView()
}
