import SwiftUI

struct CSSToSwiftUIShadowDevTool: DevTool {
    let id = "css-to-shadow"
    let name = "CSS to SwiftUI Shadow"
    let category: DevToolCategory = .uiDesign
    let icon = "shadow"
    let description = "Convert CSS box-shadow to SwiftUI shadow modifier"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "10px 10px 5px 0px rgba(0,0,0,0.75)") { input in
            ".shadow(color: Color.black.opacity(0.75), radius: 5, x: 10, y: 10)"
        }
    }
}
