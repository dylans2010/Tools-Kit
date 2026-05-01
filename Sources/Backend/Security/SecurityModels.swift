import Foundation

enum VaultCategory: String, Codable, CaseIterable, Identifiable {
    case credentials = "Credentials"
    case documents = "Documents"
    case photos = "Photos"
    case files = "Files"
    case totp = "TOTP"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .credentials: return "key.fill"
        case .documents: return "doc.text.fill"
        case .photos: return "photo.fill"
        case .files: return "folder.fill"
        case .totp: return "clock.fill"
        }
    }
}

struct VaultItem: Identifiable, Codable {
    let id: UUID
    var category: VaultCategory
    var title: String
    var note: String
    var createdAt: Date
    var updatedAt: Date

    // Encrypted payload identifier (filename or keychain key)
    var payloadIdentifier: String

    // Metadata for UI
    var metadata: [String: String]

    init(id: UUID = UUID(), category: VaultCategory, title: String, note: String = "", payloadIdentifier: String, metadata: [String: String] = [:]) {
        self.id = id
        self.category = category
        self.title = title
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
        self.payloadIdentifier = payloadIdentifier
        self.metadata = metadata
    }
}

struct CredentialData: Codable {
    var username: String
    var password: String
    var website: String
}

struct DocumentData: Codable {
    var documentType: String // ID, Passport, etc.
    var expirationDate: Date?
}

struct TOTPData: Codable {
    var secret: String
    var issuer: String
    var account: String
    var digits: Int = 6
    var period: Int = 30
}
