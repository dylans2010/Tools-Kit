import Foundation

public struct LocalizationLocale: Identifiable, Codable, Hashable {
    public var id: String { code }
    public var code: String
    public var name: String
    public var flag: String
    public var translatedKeys: Int
    public var totalKeys: Int
    public var progress: Double {
        totalKeys == 0 ? 0 : Double(translatedKeys) / Double(totalKeys)
    }

    public init(code: String, name: String, flag: String, translatedKeys: Int, totalKeys: Int) {
        self.code = code
        self.name = name
        self.flag = flag
        self.translatedKeys = translatedKeys
        self.totalKeys = totalKeys
    }
}

extension String: Identifiable {
    public var id: String { self }
}

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
