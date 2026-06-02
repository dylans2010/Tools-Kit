import SwiftUI

struct DynamicTypePreviewerDevTool: DevTool {
    let id = "dynamic-type-preview"
    let name = "Dynamic Type Previewer"
    let category: DevToolCategory = .uiDesign
    let icon = "text.magnifyingglass"
    let description = "Preview how text scales with Dynamic Type settings"

    func render() -> some View {
        List {
            Text("Large Title").font(.largeTitle)
            Text("Title 1").font(.title)
            Text("Title 2").font(.title2)
            Text("Title 3").font(.title3)
            Text("Headline").font(.headline)
            Text("Body").font(.body)
            Text("Callout").font(.callout)
            Text("Subheadline").font(.subheadline)
            Text("Footnote").font(.footnote)
            Text("Caption 1").font(.caption)
            Text("Caption 2").font(.caption2)
        }
    }
}
