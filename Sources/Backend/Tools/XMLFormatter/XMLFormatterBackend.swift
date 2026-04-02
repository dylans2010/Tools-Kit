import Foundation

class XMLFormatterBackend: ObservableObject {
    @Published var xml = ""
    @Published var error: String?

    func format() {
        error = nil

        guard !xml.isEmpty else {
            error = "Please enter XML to format"
            return
        }

        do {
            let xmlData = xml.data(using: .utf8)!
            let xmlDoc = try XMLDocument(data: xmlData, options: [])
            let formattedXML = xmlDoc.xmlString(options: [.nodePrettyPrint])
            xml = formattedXML
        } catch {
            self.error = "Invalid XML: \(error.localizedDescription)"
        }
    }

    func minify() {
        error = nil

        guard !xml.isEmpty else {
            error = "Please enter XML to minify"
            return
        }

        do {
            let xmlData = xml.data(using: .utf8)!
            let xmlDoc = try XMLDocument(data: xmlData, options: [])
            let minifiedXML = xmlDoc.xmlString(options: [.nodeCompactEmptyElement])
            xml = minifiedXML.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "  ", with: "")
        } catch {
            self.error = "Invalid XML: \(error.localizedDescription)"
        }
    }
}
