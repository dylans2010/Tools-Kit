import SwiftUI

struct ImageCompressorDevTool: DevTool {
    let id = "image-compressor"
    let name = "Image Compressor"
    let category: DevToolCategory = .performance
    let icon = "arrow.down.right.and.arrow.up.left"
    let description = "Simulate image compression and quality reduction"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Original Size (KB)") { input in
            let size = Double(input) ?? 0
            return "Compressed: \(size * 0.7) KB (70% quality)"
        }
    }
}
