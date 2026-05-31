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
        let totalKeys = max(store.localizationKeys.count, 120)
        self.locales = [
            LocalizationLocale(code: "en", name: "English", translatedKeys: totalKeys, totalKeys: totalKeys),
            LocalizationLocale(code: "es", name: "Spanish", translatedKeys: min(45, totalKeys), totalKeys: totalKeys)
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
        let updatedKeys = current
        await MainActor.run { self.keys = updatedKeys }
    }

    public func deleteKey(id: UUID) async throws {
        var current = store.localizationKeys
        current.removeAll { $0.id == id }
        store.saveLocalizationKeys(current)
        let updatedKeys = current
        await MainActor.run { self.keys = updatedKeys }
    }

    public func addLocale(_ locale: LocalizationLocale) async throws {
        await MainActor.run {
            if let index = locales.firstIndex(where: { $0.id == locale.id }) {
                locales[index] = locale
            } else {
                locales.append(locale)
            }
        }
    }

    public func syncTranslations(appID: UUID) async throws {
        let appKeys = store.localizationKeys.filter { $0.appID == appID }
        let totalKeys = appKeys.count
        await MainActor.run {
            locales = locales.map { locale in
                guard locale.appID == appID else { return locale }
                var syncedLocale = locale
                syncedLocale.totalKeys = totalKeys
                syncedLocale.translatedKeys = appKeys.filter { !$0.translations[locale.code, default: ""].isEmpty }.count
                return syncedLocale
            }
        }
    }

    public var overallProgress: Double {
        if locales.isEmpty { return 0 }
        return locales.map { $0.progress }.reduce(0, +) / Double(locales.count)
    }

    public var totalPendingKeys: Int {
        locales.map { $0.totalKeys - $0.translatedKeys }.reduce(0, +)
    }
}
