import Foundation

public struct LocalizationKey: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var key: String
    public var translations: [String: String] // languageCode: translation

    public init(id: UUID = UUID(), appID: UUID, key: String, translations: [String: String] = [:]) {
        self.id = id
        self.appID = appID
        self.key = key
        self.translations = translations
    }
}
