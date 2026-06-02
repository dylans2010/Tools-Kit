import SwiftUI

struct MIMETypeLookupDevTool: DevTool {
    let id = "mime-lookup"
    let name = "MIME Type Lookup"
    let category: DevToolCategory = .networking
    let icon = "doc.on.doc"
    let description = "Lookup MIME types for file extensions"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: ".json") { input in
            let types = [".json": "application/json", ".html": "text/html", ".png": "image/png", ".pdf": "application/pdf"]
            return types[input.lowercased()] ?? "Unknown MIME type"
        }
    }
}
