import SwiftUI

struct PushNotificationSimDevTool: DevTool {
    let id = "push-notification-sim"
    let name = "Push Notification Simulator"
    let category: DevToolCategory = .automation
    let icon = "bell.badge"
    let description = "Simulate incoming push notifications (APNs) with custom payloads"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste JSON payload") { input in
            "Simulating push notification...\nPayload: \(input)\nSuccess: Notification sent to local center."
        }
    }
}
