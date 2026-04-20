import Foundation

enum GmailAuthSupport {
    static func cleanedAccessToken(from rawToken: String?) -> String? {
        guard let rawToken else { return nil }
        let trimmed = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned: String
        if trimmed.lowercased().hasPrefix("bearer ") {
            cleaned = String(trimmed.dropFirst("bearer ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            cleaned = trimmed
        }
        return cleaned.isEmpty ? nil : cleaned
    }

    static func normalizedAccessToken(from rawToken: String?, errorDomain: String, errorMessage: String) throws -> String {
        guard let cleaned = cleanedAccessToken(from: rawToken) else {
            throw NSError(domain: errorDomain, code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return cleaned
    }

    static func isBearerTokenType(_ tokenType: String?, loggerContext: String) -> Bool {
        guard let tokenType else {
            InternalLogger.shared.log("\(loggerContext): Google token_type missing; proceeding with access token", level: .warning)
            return true
        }
        return tokenType.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare("Bearer") == .orderedSame
    }
}
