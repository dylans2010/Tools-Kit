import Foundation

struct MailAccount: Identifiable, Codable {
    let id: UUID
    let email: String
    let provider: MailProviderType
    var isEnabled: Bool

    enum MailProviderType: String, Codable {
        case iCloud
        case gmail // Placeholder for future
    }
}
