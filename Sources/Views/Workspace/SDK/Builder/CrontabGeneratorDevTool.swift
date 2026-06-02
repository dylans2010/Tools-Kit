import SwiftUI

struct CrontabGeneratorDevTool: DevTool {
    let id = "crontab-gen"
    let name = "Crontab Generator"
    let category: DevToolCategory = .automation
    let icon = "clock.badge.checkmark"
    let description = "Easily generate crontab schedules"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Every 5 minutes") { _ in "*/5 * * * *" }
    }
}
