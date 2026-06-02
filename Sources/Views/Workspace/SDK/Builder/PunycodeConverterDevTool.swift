import SwiftUI

struct PunycodeConverterDevTool: DevTool {
    let id = "punycode-converter"
    let name = "Punycode Converter"
    let category: DevToolCategory = .encoding
    let icon = "text.magnifyingglass"
    let description = "Convert Unicode domains to ASCII Punycode and back"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter domain (e.g. münchen.de)") { input in
            if input.contains("xn--") {
                // Mock decode for simulation
                return "Decoded: " + input.replacingOccurrences(of: "xn--", with: "") + ".com"
            } else {
                // Mock encode for simulation
                return "Encoded: xn--" + input.replacingOccurrences(of: "ü", with: "u") + "-7ta.de"
            }
        }
    }
}
