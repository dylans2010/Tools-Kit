import Foundation

enum GmailAuthSupport {
    private static let bearerScheme = "Bearer"

    static func cleanedAccessToken(from rawToken: String?) -> String? {
        guard let rawToken else { return nil }
        let lowercasedScheme = bearerScheme.lowercased()
        let lowercasedPrefix = "\(lowercasedScheme) "
        let trimmed = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned: String
        if trimmed.lowercased().hasPrefix(lowercasedPrefix) {
            cleaned = String(trimmed.dropFirst(lowercasedPrefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
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
            InternalLogger.shared.log("\(loggerContext): Google token_type missing; rejecting token response", level: .error)
            return false
        }
        return tokenType.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(bearerScheme) == .orderedSame
    }
}
