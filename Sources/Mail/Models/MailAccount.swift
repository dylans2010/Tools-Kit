import Foundation

struct MailAccount: Identifiable, Codable {
    let id: String
    var emailAddress: String
    var providerType: ProviderType
    var displayName: String
    var accessToken: String?
    var refreshToken: String?
    var imapHost: String?
    var imapPort: UInt16?
    var smtpHost: String?
    var smtpPort: UInt16?
    var isActive: Bool

    enum ProviderType: String, Codable, CaseIterable {
        case gmail
        case outlook
        case yahoo
        case proton
        case imap
        case icloud

        var displayName: String {
            switch self {
            case .gmail: return "Gmail"
            case .outlook: return "Outlook"
            case .yahoo: return "Yahoo Mail"
            case .proton: return "Proton Mail"
            case .imap: return "IMAP / Other"
            case .icloud: return "iCloud"
            }
        }

        func isValidAddress(_ email: String) -> Bool {
            let normalized = email.lowercased()
            switch self {
            case .gmail:
                return GmailServerConfiguration.isGmailAddress(normalized)
            case .outlook:
                return normalized.hasSuffix("@outlook.com") || normalized.hasSuffix("@hotmail.com") || normalized.hasSuffix("@live.com")
            case .yahoo:
                return normalized.hasSuffix("@yahoo.com") || normalized.hasSuffix("@ymail.com")
            case .proton:
                return Self.isValidEmail(normalized)
            case .imap:
                return Self.isValidEmail(normalized)
            case .icloud:
                return normalized.hasSuffix("@icloud.com") || normalized.hasSuffix("@me.com") || normalized.hasSuffix("@mac.com")
            }
        }

        private static func isValidEmail(_ value: String) -> Bool {
            let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
            return value.range(of: pattern, options: .regularExpression) != nil
        }

        static let iCloud: ProviderType = .icloud
    }

    // Backward-compatible alias for existing usage across mail views/services.
    typealias MailProviderType = ProviderType

    var email: String { emailAddress }
    var provider: ProviderType { providerType }
    var isEnabled: Bool { isActive }

    init(
        id: String = UUID().uuidString,
        emailAddress: String,
        providerType: ProviderType,
        displayName: String,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        imapHost: String? = nil,
        imapPort: UInt16? = nil,
        smtpHost: String? = nil,
        smtpPort: UInt16? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.emailAddress = emailAddress
        self.providerType = providerType
        self.displayName = displayName
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.imapHost = imapHost
        self.imapPort = imapPort
        self.smtpHost = smtpHost
        self.smtpPort = smtpPort
        self.isActive = isActive
    }

    // Compatibility initializer for legacy call sites.
    init(id: UUID, email: String, provider: MailProviderType, isEnabled: Bool) {
        self.init(
            id: id.uuidString,
            emailAddress: email,
            providerType: provider,
            displayName: provider.displayName,
            accessToken: nil,
            refreshToken: nil,
            imapHost: nil,
            imapPort: nil,
            smtpHost: nil,
            smtpPort: nil,
            isActive: isEnabled
        )
    }
}
