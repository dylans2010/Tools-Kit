import SwiftUI
import UIKit

struct OCRToolView: View {
    @StateObject private var backend = OCRToolBackend()
    var body: some View {
        VStack(spacing: 20) {
            Text(backend.extractedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            Button("Extract Text from Image") {
                backend.extractText(from: UIImage())
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("OCR")
    }
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
