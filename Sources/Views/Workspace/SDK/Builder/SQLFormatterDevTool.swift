import SwiftUI

struct SQLFormatterDevTool: DevTool {
    let id = "sql-formatter"
    let name = "SQL Formatter"
    let category: DevToolCategory = .data
    let icon = "tablecells.fill"
    let description = "Prettify and format raw SQL queries"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste raw SQL") { input in
            let keywords = ["SELECT", "FROM", "WHERE", "JOIN", "ON", "GROUP BY", "ORDER BY", "LIMIT", "INSERT INTO", "UPDATE", "DELETE"]
            var formatted = input
            for kw in keywords {
                formatted = formatted.replacingOccurrences(of: kw, with: "\n\(kw)", options: .caseInsensitive)
            }
            return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
