import Foundation

enum OutlookServerConfiguration {
    static let imapHost = "outlook.office365.com"
    static let imapPort: UInt16 = 993
    static let smtpHost = "smtp.office365.com"
    static let smtpPort: UInt16 = 587

    static func isOutlookAddress(_ email: String) -> Bool {
        let normalized = email.lowercased()
        return normalized.hasSuffix("@outlook.com")
            || normalized.hasSuffix("@hotmail.com")
            || normalized.hasSuffix("@live.com")
            || normalized.hasSuffix("@msn.com")
    }
}
