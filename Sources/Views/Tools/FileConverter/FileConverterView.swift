import SwiftUI
struct FileConverterView: View {
    @StateObject private var backend = FileConverterBackend()
    var body: some View {
        VStack {
            if backend.isConverting { ProgressView("Converting...", value: backend.conversionProgress, total: 1.0) }
            Button("Convert Mock File") { backend.convert(fileURL: URL(fileURLWithPath: "test.docx"), to: "PDF") }
        }
        .navigationTitle("File Converter")
    }
}
struct FileConverterTool: Tool {
    let name = "Universal Converter"
    let icon = "arrow.triangle.2.circlepath.doc"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Convert between various file formats"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(FileConverterView()) }
}
