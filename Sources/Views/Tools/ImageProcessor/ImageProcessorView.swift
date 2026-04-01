import SwiftUI
struct ImageProcessorView: View {
    @StateObject private var backend = ImageProcessorBackend()
    var body: some View { Button("Compress") { backend.compressImage(UIImage()) }.navigationTitle("Image Processor") }
}
struct ImageProcessorTool: Tool {
    let name = "Image Processor"
    let icon = "paintbrush"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Compress and resize images"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = true
    let complexityLevel = 2
    var view: AnyView { AnyView(ImageProcessorView()) }
}
