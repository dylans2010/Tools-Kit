import SwiftUI

struct FontMetricDevTool: DevTool {
    let id = "font-metric"
    let name = "Font Metric Inspector"
    let category: DevToolCategory = .uiDesign
    let icon = "textformat"
    let description = "Inspect point sizes and line heights for all system fonts"

    var body: some View {
        List {
            fontRow("Large Title", .largeTitle)
            fontRow("Title", .title)
            fontRow("Headline", .headline)
            fontRow("Body", .body)
            fontRow("Callout", .callout)
            fontRow("Footnote", .footnote)
            fontRow("Caption", .caption)
        }
    }

    private func fontRow(_ name: String, _ style: Font) -> some View {
        VStack(alignment: .leading) {
            Text(name).font(style)
            Text("Style: \(name)").font(.caption2).foregroundStyle(.secondary)
        }
    }

    func render() -> some View {
        self
    }
}
