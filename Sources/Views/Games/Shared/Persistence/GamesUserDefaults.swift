import Foundation

enum GamesUserDefaults {
    static let suiteName = "group.tools-kit.games"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }

    static func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    static func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    static func integer(forKey key: String) -> Int {
        defaults.integer(forKey: key)
    }
}
