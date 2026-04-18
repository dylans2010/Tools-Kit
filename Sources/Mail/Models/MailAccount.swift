import Foundation

struct MailAccount: Identifiable, Codable {
    let id: String
    var emailAddress: String
    var providerType: ProviderType
    var displayName: String
    var accessToken: String?
    var refreshToken: String?
    var isActive: Bool

    enum ProviderType: String, Codable, CaseIterable {
        case gmail
        case icloud
        case yahoo
        case outlook

        var displayName: String {
            switch self {
            case .gmail: return "Gmail"
            case .icloud: return "iCloud"
            case .yahoo: return "Yahoo"
            case .outlook: return "Outlook"
            }
        }

        func isValidAddress(_ email: String) -> Bool {
            let normalized = email.lowercased()
            switch self {
            case .gmail:
                return GmailServerConfiguration.isGmailAddress(normalized)
            case .icloud:
                return normalized.hasSuffix("@icloud.com") || normalized.hasSuffix("@me.com") || normalized.hasSuffix("@mac.com")
            case .yahoo:
                return YahooServerConfiguration.isYahooAddress(normalized)
            case .outlook:
                return OutlookServerConfiguration.isOutlookAddress(normalized)
            }
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
        isActive: Bool = false
    ) {
        self.id = id
        self.emailAddress = emailAddress
        self.providerType = providerType
        self.displayName = displayName
        self.accessToken = accessToken
        self.refreshToken = refreshToken
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
            isActive: isEnabled
        )
    }
}
