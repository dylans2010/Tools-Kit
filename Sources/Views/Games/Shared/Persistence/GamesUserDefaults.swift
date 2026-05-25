import Foundation

struct GamesUserDefaults {
    private static let defaults = UserDefaults(suiteName: "group.tools-kit.games") ?? .standard

    static func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    static func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    static func integer(forKey key: String) -> Int {
        defaults.integer(forKey: key)
    }

    static func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    static func double(forKey key: String) -> Double {
        defaults.double(forKey: key)
    }

    static func date(forKey key: String) -> Date? {
        defaults.object(forKey: key) as? Date
    }

    static func setDate(_ date: Date, forKey key: String) {
        defaults.set(date, forKey: key)
    }

    static func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    static func setData(_ data: Data, forKey key: String) {
        defaults.set(data, forKey: key)
    }
}
