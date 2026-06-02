import SwiftUI

struct SwiftUIAlignmentGuideDevTool: DevTool {
    let id = "swiftui-alignment"
    let name = "SwiftUI Alignment Guide"
    let category: DevToolCategory = .uiDesign
    let icon = "align.horizontal.left"
    let description = "Cheat sheet and visualizer for SwiftUI alignments"

    func render() -> some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                Rectangle().fill(.red).frame(width: 50, height: 50)
                Rectangle().fill(.blue).frame(width: 50, height: 100)
            }.border(.gray)
            Text(".top alignment")

            HStack(alignment: .bottom) {
                Rectangle().fill(.red).frame(width: 50, height: 50)
                Rectangle().fill(.blue).frame(width: 50, height: 100)
            }.border(.gray)
            Text(".bottom alignment")
        }.padding()
    }
}
