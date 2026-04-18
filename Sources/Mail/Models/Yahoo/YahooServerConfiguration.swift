import Foundation

enum YahooServerConfiguration {
    static let imapHost = "imap.mail.yahoo.com"
    static let imapPort: UInt16 = 993
    static let smtpHost = "smtp.mail.yahoo.com"
    static let smtpPort: UInt16 = 587

    static func isYahooAddress(_ email: String) -> Bool {
        let normalized = email.lowercased()
        return normalized.hasSuffix("@yahoo.com")
            || normalized.hasSuffix("@yahoo.co.uk")
            || normalized.hasSuffix("@yahoo.co.jp")
            || normalized.hasSuffix("@ymail.com")
            || normalized.hasSuffix("@rocketmail.com")
    }
}
