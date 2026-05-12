import Foundation

enum MailSettingsPersistence: Sendable {
    static func loadDictionary(forKey key: String) -> [String: String] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    static func saveDictionary(_ value: [String: String], forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    static func loadBoolDictionary(forKey key: String) -> [String: Bool] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: Bool] ?? [:]
    }

    static func saveBoolDictionary(_ value: [String: Bool], forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
