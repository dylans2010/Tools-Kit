import SwiftUI
struct FileConverterView: View {
    @StateObject private var backend = FileConverterBackend()
    var body: some View {
        VStack(spacing: 20) {
            if backend.isConverting {
                ProgressView("Converting...", value: backend.conversionProgress, total: 1.0)
                    .padding()
            }
            Button("Convert Mock File") {
                backend.convert(fileURL: URL(fileURLWithPath: "test.docx"), to: "PDF")
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
