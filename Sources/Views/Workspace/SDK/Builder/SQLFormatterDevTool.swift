import SwiftUI

struct SQLFormatterDevTool: DevTool {
    let id = "sql-formatter"
    let name = "SQL Formatter"
    let category: DevToolCategory = .data
    let icon = "tablecells"
    let description = "Format and beautify SQL queries"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "SELECT * FROM users WHERE id = 1") { input in
            let keywords = ["SELECT", "FROM", "WHERE", "JOIN", "LEFT JOIN", "INNER JOIN", "GROUP BY", "ORDER BY", "HAVING", "LIMIT", "UPDATE", "SET", "INSERT INTO", "VALUES", "DELETE"]
            var formatted = input
            for keyword in keywords {
                formatted = formatted.replacingOccurrences(of: keyword, with: "\n" + keyword, options: .caseInsensitive)
            }
            return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
