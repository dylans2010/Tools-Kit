import Foundation
import Combine

@MainActor
public final class SDKLocalizationManager: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKLocalizationManager()

    @Published public private(set) var currentLocale: SDKLocale = .english
    @Published public private(set) var availableLocales: [SDKLocale] = SDKLocale.allCases
    @Published public private(set) var translations: [String: [SDKLocale: String]] = [:]
    @Published public private(set) var missingKeys: [String] = []

    private init() {
        loadDefaultTranslations()
    }

    // MARK: - Locale Management

    public func setLocale(_ locale: SDKLocale) {
        currentLocale = locale
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.i18n",
            name: "locale.changed",
            data: ["locale": locale.rawValue]
        ))
    }

    // MARK: - Translation

    public func localize(_ key: String, locale: SDKLocale? = nil) -> String {
        let target = locale ?? currentLocale
        if let value = translations[key]?[target] {
            return value
        }
        if let fallback = translations[key]?[.english] {
            if !missingKeys.contains(key) { missingKeys.append(key) }
            return fallback
        }
        if !missingKeys.contains(key) { missingKeys.append(key) }
        return key
    }

    public func localize(_ key: String, arguments: [String], locale: SDKLocale? = nil) -> String {
        var result = localize(key, locale: locale)
        for (index, arg) in arguments.enumerated() {
            result = result.replacingOccurrences(of: "{\(index)}", with: arg)
        }
        return result
    }

    // MARK: - Registration

    public func register(key: String, translations localizedValues: [SDKLocale: String]) {
        translations[key] = localizedValues
    }

    public func registerBatch(_ batch: [String: [SDKLocale: String]]) {
        for (key, values) in batch {
            translations[key] = values
        }
    }

    // MARK: - Inspection

    public func allKeys() -> [String] {
        Array(translations.keys).sorted()
    }

    public func coverage(for locale: SDKLocale) -> Double {
        guard !translations.isEmpty else { return 0 }
        let translated = translations.values.count(where: { $0[locale] != nil })
        return Double(translated) / Double(translations.count)
    }

    public func untranslatedKeys(for locale: SDKLocale) -> [String] {
        translations.filter { $0.value[locale] == nil }.map(\.key).sorted()
    }

    // MARK: - Export/Import

    public func exportJSON(for locale: SDKLocale) -> [String: String] {
        var result: [String: String] = [:]
        for (key, values) in translations {
            if let value = values[locale] {
                result[key] = value
            }
        }
        return result
    }

    public func importJSON(_ json: [String: String], for locale: SDKLocale) {
        for (key, value) in json {
            if translations[key] != nil {
                translations[key]?[locale] = value
            } else {
                translations[key] = [locale: value]
            }
        }
    }

    // MARK: - Defaults

    private func loadDefaultTranslations() {
        registerBatch([
            "sdk.welcome": [.english: "Welcome", .spanish: "Bienvenido", .french: "Bienvenue", .german: "Willkommen", .japanese: "ようこそ"],
            "sdk.settings": [.english: "Settings", .spanish: "Ajustes", .french: "Parametres", .german: "Einstellungen", .japanese: "設定"],
            "sdk.search": [.english: "Search", .spanish: "Buscar", .french: "Rechercher", .german: "Suchen", .japanese: "検索"],
            "sdk.save": [.english: "Save", .spanish: "Guardar", .french: "Enregistrer", .german: "Speichern", .japanese: "保存"],
            "sdk.cancel": [.english: "Cancel", .spanish: "Cancelar", .french: "Annuler", .german: "Abbrechen", .japanese: "キャンセル"],
            "sdk.delete": [.english: "Delete", .spanish: "Eliminar", .french: "Supprimer", .german: "Loschen", .japanese: "削除"],
            "sdk.error": [.english: "Error", .spanish: "Error", .french: "Erreur", .german: "Fehler", .japanese: "エラー"],
            "sdk.loading": [.english: "Loading...", .spanish: "Cargando...", .french: "Chargement...", .german: "Laden...", .japanese: "読み込み中..."],
            "sdk.retry": [.english: "Retry", .spanish: "Reintentar", .french: "Reessayer", .german: "Wiederholen", .japanese: "再試行"],
            "sdk.done": [.english: "Done", .spanish: "Hecho", .french: "Termine", .german: "Fertig", .japanese: "完了"],
        ])
    }
}

// MARK: - Models

public enum SDKLocale: String, Codable, CaseIterable, Sendable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case chinese = "zh"
    case korean = "ko"
    case portuguese = "pt"
    case italian = "it"
    case arabic = "ar"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .japanese: return "Japanese"
        case .chinese: return "Chinese"
        case .korean: return "Korean"
        case .portuguese: return "Portuguese"
        case .italian: return "Italian"
        case .arabic: return "Arabic"
        }
    }
}
