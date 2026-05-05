import Foundation

final class PluginPrerequisiteEngine {
    static func checkPrerequisites(plugin: PluginDefinition) -> [PluginPrerequisite] {
        var unmet: [PluginPrerequisite] = []

        for cap in plugin.capabilities {
            switch cap {
            case .notes: if !isServiceEnabled(.notes) { unmet.append(.notes) }
            case .github: if !isServiceEnabled(.repo) { unmet.append(.repo) }
            case .mail: if !isServiceEnabled(.mail) { unmet.append(.mail) }
            case .ai, .aiPersonaQuery: if !isServiceEnabled(.ai) { unmet.append(.ai) }
            case .automation: if !isServiceEnabled(.automation) { unmet.append(.automation) }
            case .calendar: if !isServiceEnabled(.calendar) { unmet.append(.calendar) }
            default: break
            }
        }

        return unmet
    }

    private static func isServiceEnabled(_ prerequisite: PluginPrerequisite) -> Bool {
        switch prerequisite {
        case .notes:
            return !NotebooksManager.shared.notebooks.isEmpty
        case .repo:
            return true // Assuming GitHub is connected if needed
        case .mail:
            return MailStore.shared.activeAccount != nil
        case .ai:
            return true // AI is usually always available
        case .automation:
            return true
        case .calendar:
            return true
        }
    }
}
