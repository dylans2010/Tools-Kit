import SwiftUI
import UIKit

struct OCRToolView: View {
    @StateObject private var backend = OCRToolBackend()
    var body: some View { VStack { Text(backend.extractedText); Button("Extract") { backend.extractText(from: UIImage()) } }.navigationTitle("OCR") }
}
struct OCRTool: Tool {
    let name = "OCR Tool"
    let icon = "text.viewfinder"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Extract text from images"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = true
    let complexityLevel = 3
    var view: AnyView { AnyView(OCRToolView()) }
}
