import Foundation

struct AISlidesSchemeDecoder {
    func decode(_ raw: String) throws -> GenSlidesScheme {
        let cleaned = repairJSON(raw)
        guard let data = cleaned.data(using: .utf8) else {
            throw SlideValidationError.decodingFailed(underlying: NSError(domain: "AISlidesSchemeDecoder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8"]))
        }

        do {
            return try JSONDecoder().decode(GenSlidesScheme.self, from: data)
        } catch {
            print("[AISlidesSchemeDecoder] First decode failed: \(error.localizedDescription), attempting repair")
            let repaired = aggressiveRepairJSON(cleaned)
            guard let repairedData = repaired.data(using: .utf8) else {
                throw SlideValidationError.decodingFailed(underlying: error)
            }
            do {
                return try JSONDecoder().decode(GenSlidesScheme.self, from: repairedData)
            } catch {
                throw SlideValidationError.decodingFailed(underlying: error)
            }
        }
    }

    private func repairJSON(_ raw: String) -> String {
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

        return cleaned
    }

    private func aggressiveRepairJSON(_ raw: String) -> String {
        var cleaned = raw
        cleaned = cleaned.replacingOccurrences(of: ",]", with: "]")
        cleaned = cleaned.replacingOccurrences(of: ",}", with: "}")

        cleaned = cleaned.replacingOccurrences(of: "\t", with: " ")

        let controlChars = CharacterSet.controlCharacters.subtracting(.newlines)
        cleaned = cleaned.unicodeScalars.filter { !controlChars.contains($0) }.map(String.init).joined()

        return cleaned
    }
}
