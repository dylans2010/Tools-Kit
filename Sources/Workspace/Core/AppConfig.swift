import Foundation

enum AppConfig: Sendable {
    private static let logger = InternalLogger.shared

    static func string(for key: String) -> String? {
        guard let dictionary = Bundle.main.infoDictionary else {
            logger.log("AppConfig: Info.plist dictionary unavailable", level: .error)
            return nil
        }

        guard let value = dictionary[key] as? String else {
            logger.log("AppConfig: missing key \(key)", level: .warning)
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            logger.log("AppConfig: empty key \(key)", level: .warning)
            return nil
        }

        return trimmed
    }

    static var googleClientID: String? { string(for: "GOOGLE_CLIENT_ID") }
    static var microsoftClientID: String? { string(for: "MICROSOFT_CLIENT_ID") }
    static var yahooClientID: String? { string(for: "YAHOO_CLIENT_ID") }

    static var googleRedirectURI: String? { string(for: "GOOGLE_OAUTH_REDIRECT_URI") }
    static var microsoftRedirectURI: String? { string(for: "MICROSOFT_OAUTH_REDIRECT_URI") }
    static var yahooRedirectURI: String? { string(for: "YAHOO_OAUTH_REDIRECT_URI") }
}
