import SwiftUI

struct FontPreviewerDevTool: DevTool {
    let id = "font-previewer"
    let name = "Font Previewer"
    let category: DevToolCategory = .uiDesign
    let icon = "textformat"
    let description = "Preview all system fonts available on iOS"

    func render() -> some View {
        List {
            ForEach(UIFont.familyNames.sorted(), id: \.self) { family in
                Section(family) {
                    ForEach(UIFont.fontNames(forFamilyName: family), id: \.self) { name in
                        Text(name)
                            .font(.custom(name, size: 16))
                    }
                }
            }
        }
    }
}
