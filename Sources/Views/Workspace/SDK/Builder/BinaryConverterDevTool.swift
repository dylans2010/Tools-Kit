import SwiftUI

struct BinaryConverterDevTool: DevTool {
    let id = "binary-converter"
    let name = "Binary Converter"
    let category: DevToolCategory = .encoding
    let icon = "01.square"
    let description = "Convert text to binary representation"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text") { $0.utf8.map { String($0, radix: 2).leftPadded(to: 8) }.joined(separator: " ") } }
}
