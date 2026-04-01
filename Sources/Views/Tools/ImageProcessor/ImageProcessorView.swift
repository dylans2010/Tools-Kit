import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ImageProcessorView: View {
    @StateObject private var backend = ImageProcessorBackend()
    var body: some View {
        VStack(spacing: 16) {
            Button("Compress Image") {
                #if canImport(UIKit)
                backend.compressImage(UIImage())
                #endif
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Image Processor")
    }
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
