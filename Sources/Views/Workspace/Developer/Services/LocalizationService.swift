import Foundation

public class LocalizationService: ObservableObject {
    public static let shared = LocalizationService()
    private let store = DeveloperPersistentStore.shared

    @Published public var keys: [LocalizationKey] = []
    @Published public var locales: [LocalizationLocale] = []

    private init() {
        loadKeys()
        loadLocales()
    }

    public func loadKeys() { self.keys = store.localizationKeys }

    public func loadLocales() {
        // Mocking some locales since store doesn't have them yet, but using the real model
        self.locales = [
            LocalizationLocale(code: "en", name: "English", flag: "🇺🇸", translatedKeys: 120, totalKeys: 120),
            LocalizationLocale(code: "es", name: "Spanish", flag: "🇪🇸", translatedKeys: 45, totalKeys: 120)
        ]
    }

    public func saveKey(_ key: LocalizationKey) async throws {
        var current = store.localizationKeys
        if let index = current.firstIndex(where: { $0.id == key.id }) {
            current[index] = key
        } else {
            current.append(key)
        }
        store.saveLocalizationKeys(current)
        await MainActor.run { self.keys = current }
    }

    public func deleteKey(id: UUID) async throws {
        var current = store.localizationKeys
        current.removeAll { $0.id == id }
        store.saveLocalizationKeys(current)
        await MainActor.run { self.keys = current }
    }

    public func addLocale(_ locale: LocalizationLocale) {
        locales.append(locale)
    }

    public var overallProgress: Double {
        if locales.isEmpty { return 0 }
        return locales.map { $0.progress }.reduce(0, +) / Double(locales.count)
    }

    public var totalPendingKeys: Int {
        locales.map { $0.totalKeys - $0.translatedKeys }.reduce(0, +)
    }
}
