import SwiftUI

struct ASCIIHexConverterTool: DevTool {
    let id = UUID()
    let name = "ASCII / Hex Converter"
    let category: DevToolCategory = .inputOutput
    let icon = "textformat.123"
    let description = "Convert between ASCII text and hex"
    func render() -> some View { ASCIIHexConverterDevToolView() }
}

struct ASCIIHexConverterDevToolView: View {
    @State private var asciiText = ""
    @State private var hexText = ""
    var body: some View {
        Form {
            Section("ASCII Text") {
                TextEditor(text: $asciiText).frame(minHeight: 80).font(.system(.body, design: .monospaced))
                Button("ASCII \u{2192} Hex") {
                    hexText = asciiText.utf8.map { String(format: "%02X", $0) }.joined(separator: " ")
                }
                .disabled(asciiText.isEmpty)
            }
            Section("Hex") {
                TextEditor(text: $hexText).frame(minHeight: 80).font(.system(.body, design: .monospaced))
                Button("Hex \u{2192} ASCII") {
                    let bytes = hexText.split(separator: " ").compactMap { UInt8($0, radix: 16) }
                    asciiText = String(bytes: bytes, encoding: .utf8) ?? "Invalid hex"
                }
                .disabled(hexText.isEmpty)
            }
        }
        .navigationTitle("ASCII / Hex Converter")
    }
}
