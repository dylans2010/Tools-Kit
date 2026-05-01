import Foundation

/// Defines the types of items that can be stored in the Secure Vault.
public enum VaultItemType: String, Codable, CaseIterable, Identifiable {
    case credential = "Credential"
    case document = "Document"
    case photo = "Photo"
    case file = "File"
    case totp = "TOTP"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .credential: return "key.fill"
        case .document: return "doc.text.fill"
        case .photo: return "photo.fill"
        case .file: return "folder.fill"
        case .totp: return "clock.fill"
        }
    }
}

/// The primary model for a vault item, containing metadata and references to encrypted content.
public struct VaultItem: Identifiable, Codable {
    public let id: UUID
    public var type: VaultItemType
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date

    /// Encrypted blob for small items (e.g., credentials JSON, TOTP secrets).
    public var encryptedPayload: Data?

    /// Reference to an encrypted file on disk for larger items (photos, documents, arbitrary files).
    public var fileReference: String?

    /// Metadata specific to the item type.
    public var credentialMetadata: CredentialMetadata?
    public var documentMetadata: DocumentMetadata?
    public var totpMetadata: TOTPMetadata?
    public var fileMetadata: FileMetadata?

    public init(id: UUID = UUID(), type: VaultItemType, title: String) {
        self.id = id
        self.type = type
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Metadata specific to credentials.
public struct CredentialMetadata: Codable {
    public var username: String
    public var url: String?
    public var notes: String?

    public init(username: String, url: String? = nil, notes: String? = nil) {
        self.username = username
        self.url = url
        self.notes = notes
    }
}

/// Metadata specific to sensitive documents.
public struct DocumentMetadata: Codable {
    public var documentType: String
    public var expirationDate: Date?
    public var notes: String?

    public init(documentType: String, expirationDate: Date? = nil, notes: String? = nil) {
        self.documentType = documentType
        self.expirationDate = expirationDate
        self.notes = notes
    }
}

/// Metadata and configuration for Time-based One-Time Passwords (TOTP).
public struct TOTPMetadata: Codable {
    public var issuer: String?
    public var accountName: String?
    public var digits: Int = 6
    public var period: TimeInterval = 30

    public init(issuer: String? = nil, accountName: String? = nil, digits: Int = 6, period: TimeInterval = 30) {
        self.issuer = issuer
        self.accountName = accountName
        self.digits = digits
        self.period = period
    }
}

/// Metadata for arbitrary files and photos.
public struct FileMetadata: Codable {
    public var fileName: String
    public var fileSize: Int64
    public var mimeType: String

    public init(fileName: String, fileSize: Int64, mimeType: String) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
    }
}

/// Global security configuration for the vault.
public struct SecurityConfig: Codable {
    public var isMasterPasswordSet: Bool
    public var useBiometrics: Bool
    public var salt: Data
    public var keyDerivationRounds: Int

    public init(isMasterPasswordSet: Bool = false, useBiometrics: Bool = false, salt: Data = Data(), keyDerivationRounds: Int = 100000) {
        self.isMasterPasswordSet = isMasterPasswordSet
        self.useBiometrics = useBiometrics
        self.salt = salt
        self.keyDerivationRounds = keyDerivationRounds
    }
}

/// Represents the structure of a .toolkitsec security package for export/import.
public struct SecurityPackage: Codable {
    public let header: SecurityPackageHeader
    public let encryptedBody: Data

    public init(header: SecurityPackageHeader, encryptedBody: Data) {
        self.header = header
        self.encryptedBody = encryptedBody
    }
}

public struct SecurityPackageHeader: Codable {
    public let version: Int
    public let timestamp: Date
    public let salt: Data
    public let kdfRounds: Int
    public let integrityHash: String // Hash of the DECRYPTED body
}

public struct SecurityPackageBody: Codable {
    public let items: [VaultItem]
    public let fileBlobs: [String: Data] // fileId -> encryptedData (the data itself is already encrypted)
}
