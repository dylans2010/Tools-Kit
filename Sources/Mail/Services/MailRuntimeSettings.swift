import Foundation

struct MailRuntimeSettings {
    static var undoSendEnabled: Bool {
        UserDefaults.standard.bool(forKey: "mail.settings.undoSendEnabled")
    }

    static var undoSendDelay: Int {
        let value = UserDefaults.standard.integer(forKey: "mail.settings.undoSendDelay")
        return value == 0 ? 10 : value
    }

    static var defaultSenderAccountId: String {
        UserDefaults.standard.string(forKey: "mail.settings.defaultSenderAccountId") ?? ""
    }

    static var autoSyncEnabled: Bool {
        if UserDefaults.standard.object(forKey: "mail.settings.autoSync") == nil { return true }
        return UserDefaults.standard.bool(forKey: "mail.settings.autoSync")
    }

    static var syncInterval: TimeInterval {
        switch UserDefaults.standard.string(forKey: "mail.settings.syncInterval") ?? "15 min" {
        case "Manual": return .infinity
        case "5 min": return 5 * 60
        default: return 15 * 60
        }
    }

    static var aiAutoSummarizeEnabled: Bool {
        if UserDefaults.standard.object(forKey: "mail.settings.ai.autoSummarize") == nil { return true }
        return UserDefaults.standard.bool(forKey: "mail.settings.ai.autoSummarize")
    }

    static var aiSmartReplyEnabled: Bool {
        if UserDefaults.standard.object(forKey: "mail.settings.ai.smartReply") == nil { return true }
        return UserDefaults.standard.bool(forKey: "mail.settings.ai.smartReply")
    }

    static var aiAutoCategorizeEnabled: Bool {
        if UserDefaults.standard.object(forKey: "mail.settings.ai.autoCategorize") == nil { return true }
        return UserDefaults.standard.bool(forKey: "mail.settings.ai.autoCategorize")
    }

    static var autoSortEnabled: Bool {
        UserDefaults.standard.bool(forKey: "mail.settings.autoSortEmails")
    }

    static var importantOnlyNotifications: Bool {
        UserDefaults.standard.bool(forKey: "mail.settings.importantOnlyNotifications")
    }

    static var notificationsByAccount: [String: Bool] {
        MailSettingsPersistence.loadBoolDictionary(forKey: "mail.settings.notificationsByAccount")
    }
}
