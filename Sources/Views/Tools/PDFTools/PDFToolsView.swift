import SwiftUI
struct PDFToolsView: View {
    @StateObject private var backend = PDFToolsBackend()
    var body: some View {
        VStack(spacing: 20) {
            Button("Merge PDFs") {
                backend.merge(pdfURLs: [])
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("PDF Tools")
    }
}
struct PDFTools: Tool {
    let name = "PDF Tools"
    let icon = "doc.text.below.ecg"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Merge and split PDF documents"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(PDFToolsView()) }
}
