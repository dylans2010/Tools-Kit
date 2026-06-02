import SwiftUI

struct OctalConverterDevTool: DevTool {
    let id = "octal-converter"
    let name = "Octal Converter"
    let category: DevToolCategory = .encoding
    let icon = "number.circle"
    let description = "Convert text to octal representation"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter text") { input in
            input.utf8.map { String($0, radix: 8) }.joined(separator: " ")
        }
    }
}
