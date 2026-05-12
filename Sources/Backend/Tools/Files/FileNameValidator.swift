import Foundation

struct FileNameValidator: Sendable {
    func sanitize(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let cleanedScalars = trimmed.unicodeScalars.map { scalar in
            invalidCharacters.contains(scalar) ? "_" : Character(scalar)
        }
        return String(cleanedScalars)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
