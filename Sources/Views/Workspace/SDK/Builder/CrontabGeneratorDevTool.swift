import SwiftUI

struct CrontabGeneratorDevTool: DevTool {
    let id = "crontab-generator"
    let name = "Crontab Generator"
    let category: DevToolCategory = .automation
    let icon = "clock.badge.checkmark"
    let description = "Easily generate Crontab expressions for scheduled tasks"

    func render() -> some View {
        CrontabGeneratorView()
    }
}

struct CrontabGeneratorView: View {
    @State private var minute = "*"
    @State private var hour = "*"
    @State private var day = "*"
    @State private var month = "*"
    @State private var weekday = "*"
    @State private var result = ""

    var body: some View {
        Form {
            Section("Time Units") {
                TextField("Minute", text: $minute)
                TextField("Hour", text: $hour)
                TextField("Day", text: $day)
                TextField("Month", text: $month)
                TextField("Weekday", text: $weekday)
            }
            Button("Generate Expression") {
                result = "\(minute) \(hour) \(day) \(month) \(weekday)"
            }
            .frame(maxWidth: .infinity)

            if !result.isEmpty {
                Section("Result") {
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }
}
