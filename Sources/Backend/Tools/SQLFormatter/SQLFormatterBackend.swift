import Foundation

class SQLFormatterBackend: ObservableObject {
    @Published var sql = ""

    func format() {
        guard !sql.isEmpty else { return }

        var formatted = sql
        let keywords = ["SELECT", "FROM", "WHERE", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON", "AND", "OR", "ORDER BY", "GROUP BY", "HAVING", "LIMIT", "OFFSET", "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE", "CREATE", "TABLE", "ALTER", "DROP", "AS"]

        // Add newlines before major keywords
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(formatted.startIndex..., in: formatted)
                formatted = regex.stringByReplacingMatches(in: formatted, options: [], range: range, withTemplate: "\n\(keyword)")
            }
        }

        // Clean up leading/trailing whitespace
        formatted = formatted.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        // Indent WHERE, AND, OR clauses
        formatted = formatted.components(separatedBy: .newlines)
            .map { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.uppercased().hasPrefix("AND") || trimmed.uppercased().hasPrefix("OR") || trimmed.uppercased().hasPrefix("ON") {
                    return "  " + trimmed
                }
                return trimmed
            }
            .joined(separator: "\n")

        sql = formatted
    }

    func minify() {
        sql = sql.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
