import Foundation

enum GmailServerConfiguration: Sendable {
    static let imapHost = "imap.gmail.com"
    static let imapPort: UInt16 = 993
    static let smtpHost = "smtp.gmail.com"
    static let smtpPort: UInt16 = 587

    static func isGmailAddress(_ email: String) -> Bool {
        let normalized = email.lowercased()
        return normalized.hasSuffix("@gmail.com") || normalized.hasSuffix("@googlemail.com")
    }
}
