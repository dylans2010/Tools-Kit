import SwiftUI

struct ResponsiveBreakpointDevTool: DevTool {
    let id = "responsive-breakpoint"
    let name = "Responsive Breakpoints"
    let category: DevToolCategory = .uiDesign
    let icon = "rectangle.split.3x1"
    let description = "Preview and configure responsive design breakpoints"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter custom width or use defaults") { _ in
            "iPhone SE: 375pt\niPhone 15: 393pt\niPhone 15 Pro Max: 430pt\niPad Mini: 744pt\niPad Air: 820pt\niPad Pro 11\": 834pt\niPad Pro 12.9\": 1024pt"
        }
    }
}
