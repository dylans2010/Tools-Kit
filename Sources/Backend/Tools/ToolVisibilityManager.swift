import Foundation
import Combine

/// Manages which tools are visible on the Dashboard.
/// Preferences are stored persistently in UserDefaults.
final class ToolVisibilityManager: ObservableObject {
    static let shared = ToolVisibilityManager()

    private let key = "hiddenToolIDs"

    /// IDs of tools that the user has hidden from the Dashboard.
    @Published private(set) var hiddenIDs: Set<String>

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: "hiddenToolIDs") ?? []
        hiddenIDs = Set(stored)
    }

    func isVisible(_ toolID: String) -> Bool {
        !hiddenIDs.contains(toolID)
    }

    func setVisible(_ toolID: String, visible: Bool) {
        if visible {
            hiddenIDs.remove(toolID)
        } else {
            hiddenIDs.insert(toolID)
        }
        persist()
    }

    func toggle(_ toolID: String) {
        if hiddenIDs.contains(toolID) {
            hiddenIDs.remove(toolID)
        } else {
            hiddenIDs.insert(toolID)
        }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(Array(hiddenIDs), forKey: key)
    }
}
