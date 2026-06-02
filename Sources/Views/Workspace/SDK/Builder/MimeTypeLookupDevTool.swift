import SwiftUI

struct MimeTypeLookupDevTool: DevTool {
    let id = "mime-type-lookup"
    let name = "Mime Type Lookup"
    let category: DevToolCategory = .networking
    let icon = "doc.on.doc"
    let description = "Lookup common Mime Types by extension"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter extension (e.g. .json)") { input in
            let ext = input.lowercased().hasPrefix(".") ? input.lowercased() : ".\(input.lowercased())"
            let map: [String: String] = [
                ".json": "application/json",
                ".html": "text/html",
                ".css": "text/css",
                ".js": "application/javascript",
                ".png": "image/png",
                ".jpg": "image/jpeg",
                ".pdf": "application/pdf",
                ".zip": "application/zip",
                ".xml": "application/xml"
            ]
            return map[ext] ?? "Unknown extension"
        }
    }
}
