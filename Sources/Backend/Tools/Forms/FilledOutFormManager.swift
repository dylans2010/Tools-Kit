import Foundation

enum FilledOutFormManager {
    static func exportAnswers(_ answers: FilledOutFormDocument, to url: URL) throws {
        let data = try JSONEncoder().encode(answers)
        try data.write(to: url)
    }

    static func importAnswers(from url: URL) throws -> FilledOutFormDocument {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FilledOutFormDocument.self, from: data)
    }

    static func canReviewAnswers(_ answers: FilledOutFormDocument, for form: FormDocument) -> Bool {
        guard answers.formID == form.id else { return false }
        guard !answers.ownerAccessKey.isEmpty else { return true } // legacy compatibility
        return answers.ownerAccessKey == form.ownerAccessKey
    }
}
