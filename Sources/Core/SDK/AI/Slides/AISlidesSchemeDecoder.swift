import Foundation

struct AISlidesSchemeDecoder {
    func decode(_ raw: String) throws -> GenSlidesScheme {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        if let startIndex = cleaned.firstIndex(of: "{") {
            cleaned = String(cleaned[startIndex...])
        }
        if let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[...endIndex])
        }

        guard let data = cleaned.data(using: .utf8) else {
            throw SlideValidationError.decodingFailed(underlying: NSError(domain: "AISlidesSchemeDecoder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8"]))
        }

        return try JSONDecoder().decode(GenSlidesScheme.self, from: data)
    }
}
