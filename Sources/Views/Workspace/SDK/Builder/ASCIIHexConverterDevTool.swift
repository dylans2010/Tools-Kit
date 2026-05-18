import SwiftUI

struct ASCIIHexConverterDevTool: DevTool {
    let id = "ascii-hex-converter"
    let name = "ASCII/Hex Converter"
    let category = DevToolCategory.inputOutput
    let icon = "number.square"
    let description = "Convert between ASCII and Hex"

    func render() -> some View {
        ASCIIHexConverterView()
    }
}

struct ASCIIHexConverterView: View {
    @StateObject private var viewModel = ASCIIHexConverterViewModel()

    var body: some View {
        Form {
            Section("ASCII Text") {
                TextEditor(text: $viewModel.asciiText)
                    .frame(height: 80)
                    .font(.monospaced(.body)())
            }

            Section("Hexadecimal") {
                TextEditor(text: $viewModel.hexText)
                    .frame(height: 80)
                    .font(.monospaced(.body)())
            }

            Section {
                Button("Clear") {
                    viewModel.asciiText = ""
                    viewModel.hexText = ""
                }
            }
        }
    }
}

class ASCIIHexConverterViewModel: ObservableObject {
    @Published var asciiText = "" {
        didSet {
            guard !isUpdating else { return }
            isUpdating = true
            hexText = ASCIIHexService.toHex(asciiText)
            isUpdating = false
        }
    }

    @Published var hexText = "" {
        didSet {
            guard !isUpdating else { return }
            isUpdating = true
            asciiText = ASCIIHexService.toASCII(hexText)
            isUpdating = false
        }
    }

    private var isUpdating = false
}

struct ASCIIHexService {
    static func toHex(_ ascii: String) -> String {
        return ascii.data(using: .utf8)?.map { String(format: "%02x", $0) }.joined(separator: " ") ?? ""
    }

    static func toASCII(_ hex: String) -> String {
        let cleaned = hex.replacingOccurrences(of: " ", with: "")
        var data = Data()
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2, limitedBy: cleaned.endIndex) ?? cleaned.endIndex
            if let byte = UInt8(cleaned[index..<nextIndex], radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
