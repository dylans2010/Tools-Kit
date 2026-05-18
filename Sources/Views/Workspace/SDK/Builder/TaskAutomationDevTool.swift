import SwiftUI

struct TaskAutomationDevTool: DevTool {
    let id = "task-automation"
    let name = "Task Automation"
    let category = DevToolCategory.automation
    let icon = "bolt.fill"
    let description = "Manage automated tasks"

    func render() -> some View {
        TaskAutomationView()
    }
}

struct TaskAutomationView: View {
    @State private var tasks = [
        "Cleanup Cache (Scheduled: Daily)",
        "Sync Logs (Scheduled: Hourly)"
    ]

    var body: some View {
        List {
            Section("Automated Tasks") {
                ForEach(tasks, id: \.self) { task in
                    Label(task, systemImage: "clock")
                }
            }
        }
    }
}
