import SwiftUI

struct CRONParserDevTool: DevTool {
    let id = "cron-parser"
    let name = "CRON Expression Parser"
    let category: DevToolCategory = .data
    let icon = "calendar.badge.clock"
    let description = "Parse and explain CRON schedule expressions"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "e.g. */5 * * * *") { input in let parts = input.split(separator: " "); guard parts.count == 5 else { return "Expected 5 fields: minute hour day month weekday" }; return "Minute: \(parts[0])\nHour: \(parts[1])\nDay of Month: \(parts[2])\nMonth: \(parts[3])\nDay of Week: \(parts[4])" } }
}
