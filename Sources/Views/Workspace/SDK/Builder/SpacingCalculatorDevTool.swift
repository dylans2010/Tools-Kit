import SwiftUI

struct SpacingCalculatorDevTool: DevTool {
    let id = "spacing-calculator"
    let name = "Spacing Calculator"
    let category: DevToolCategory = .uiDesign
    let icon = "ruler"
    let description = "Calculate consistent spacing scales for UI layouts"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Base unit (default: 4)") { input in let base = Double(input) ?? 4; return (1...12).map { "Step \($0): \(Int(base * Double($0)))pt" }.joined(separator: "\n") } }
}
