import Foundation

public struct LocalizationLocale: Identifiable, Codable, Hashable {
    public var id: String { [appID?.uuidString, code].compactMap { $0 }.joined(separator: "-") }
    public var appID: UUID?
    public var code: String
    public var name: String
    public var flag: String
    public var translatedKeys: Int
    public var totalKeys: Int
    public var progress: Double {
        totalKeys == 0 ? 0 : Double(translatedKeys) / Double(totalKeys)
    }
    public var completionPercentage: Double { progress }

    public init(appID: UUID? = nil, code: String, name: String, flag: String? = nil, translatedKeys: Int = 0, totalKeys: Int = 0) {
        self.appID = appID
        self.code = code
        self.name = name
        self.flag = flag ?? Self.flag(for: code)
        self.translatedKeys = translatedKeys
        self.totalKeys = totalKeys
    }

    private static func flag(for code: String) -> String {
        let lowercasedCode = code.lowercased()
        if lowercasedCode.hasPrefix("en") { return "🇺🇸" }
        if lowercasedCode.hasPrefix("es") { return "🇪🇸" }
        if lowercasedCode.hasPrefix("fr") { return "🇫🇷" }
        if lowercasedCode.hasPrefix("de") { return "🇩🇪" }
        if lowercasedCode.hasPrefix("ja") { return "🇯🇵" }
        return "🌐"
    }
}

extension String: @retroactive Identifiable {
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
