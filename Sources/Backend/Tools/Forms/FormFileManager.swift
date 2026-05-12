import Foundation

enum FormFileManager: Sendable {
    static let formExtension = "form"

    static func exportForm(_ form: FormDocument, to url: URL) throws {
        let data = try JSONEncoder().encode(form)
        try data.write(to: url)
    }

    static func importForm(from url: URL) throws -> FormDocument {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FormDocument.self, from: data)
    }
}
