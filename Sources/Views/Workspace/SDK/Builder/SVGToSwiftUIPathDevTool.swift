import SwiftUI

struct SVGToSwiftUIPathDevTool: DevTool {
    let id = "svg-to-swiftui"
    let name = "SVG to SwiftUI Path"
    let category: DevToolCategory = .uiDesign
    let icon = "bezier"
    let description = "Convert simple SVG path data (M, L, H, V, Z) to SwiftUI Path"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "M10 10 L20 20 Z") { input in
            parseSVGPath(input)
        }
    }

    private func parseSVGPath(_ svg: String) -> String {
        var swiftUI = "Path { path in\n"
        let scanner = Scanner(string: svg)
        let commands = CharacterSet(charactersIn: "MLHVZmlhvz")

        while !scanner.isAtEnd {
            guard let cmd = scanner.scanCharacters(from: commands)?.first else {
                scanner.scanCharacters(from: .whitespacesAndNewlines)
                continue
            }

            switch cmd {
            case "M", "m":
                if let x = scanner.scanDouble(), let y = scanner.scanDouble() {
                    swiftUI += "    path.move(to: CGPoint(x: \(x), y: \(y)))\n"
                }
            case "L", "l":
                if let x = scanner.scanDouble(), let y = scanner.scanDouble() {
                    swiftUI += "    path.addLine(to: CGPoint(x: \(x), y: \(y)))\n"
                }
            case "H", "h":
                if let x = scanner.scanDouble() {
                    swiftUI += "    path.addLine(to: CGPoint(x: \(x), y: lastY))\n"
                }
            case "V", "v":
                if let y = scanner.scanDouble() {
                    swiftUI += "    path.addLine(to: CGPoint(x: lastX, y: \(y)))\n"
                }
            case "Z", "z":
                swiftUI += "    path.closeSubpath()\n"
            default:
                break
            }
        }

        swiftUI += "}"
        return swiftUI
    }
}
