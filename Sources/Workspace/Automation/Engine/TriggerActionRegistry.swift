import Foundation

class TriggerActionRegistry {
    static let shared = TriggerActionRegistry()

    let availableTriggers = ["On New Task", "On Email Received", "On Calendar Event Start"]
    let availableActions = ["Send Notification", "Create Note", "Tag Task", "Email Summary"]

    private init() {}
}
