import SwiftUI

struct BinaryHexConverterDevTool: DevTool {
    let id = "binary-hex-converter"
    let name = "Binary to Hex Converter"
    let category: DevToolCategory = .encoding
    let icon = "hexagons.fill"
    let description = "Convert between binary strings and hexadecimal"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter binary (e.g. 10101010)") { input in
            let cleaned = input.replacingOccurrences(of: " ", with: "")
            guard let val = UInt64(cleaned, radix: 2) else { return "Invalid binary" }
            return "Hex: 0x\(String(val, radix: 16).uppercased())\nDecimal: \(val)"
        }
    }
}
