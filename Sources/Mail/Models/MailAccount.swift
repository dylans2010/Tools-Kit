import Foundation

struct MailAccount: Identifiable, Codable {
    let id: UUID
    let email: String
    let provider: MailProviderType
    var isEnabled: Bool

    enum MailProviderType: String, Codable {
        case iCloud
        case gmail

        var displayName: String {
            switch self {
            case .iCloud: return "iCloud"
            case .gmail: return "Gmail"
            }
        }

        func isValidAddress(_ email: String) -> Bool {
            let normalized = email.lowercased()
            switch self {
            case .iCloud:
                return normalized.hasSuffix("@icloud.com") || normalized.hasSuffix("@me.com") || normalized.hasSuffix("@mac.com")
            case .gmail:
                return GmailServerConfiguration.isGmailAddress(normalized)
            }
        }
    }
}
