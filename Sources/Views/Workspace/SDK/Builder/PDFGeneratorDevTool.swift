import SwiftUI

struct PDFGeneratorDevTool: DevTool {
    let id = "pdf-gen"
    let name = "PDF Generator"
    let category: DevToolCategory = .utilities
    let icon = "doc.richtext"
    let description = "Generate PDF files from text or markdown"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Text to convert to PDF") { input in
            "PDF metadata generated for '\(input.prefix(20))...'"
        }
    }
}
