import SwiftUI
import UIKit
struct OCRToolView: View {
    @StateObject private var backend = OCRToolBackend()
    var body: some View {
        VStack(spacing: 16) {
            if !backend.extractedText.isEmpty {
                ScrollView {
                    Text(backend.extractedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
            } else {
                Text("No text extracted yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Button("Extract Text from Image") { backend.extractText(from: UIImage()) }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("OCR Tool")
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
