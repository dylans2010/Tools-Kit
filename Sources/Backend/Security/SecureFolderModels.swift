import Foundation

struct SecureFolder: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var items: [SecureFolderItem]
    let createdAt: Date

    init(id: String = UUID().uuidString, name: String, items: [SecureFolderItem] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.items = items
        self.createdAt = createdAt
    }
}

enum SecureFolderItem: Codable, Equatable, Sendable {
    case password(id: String)
    case file(id: String)
    case photo(id: String)
    case note(id: String)
    case app(id: String)
}
