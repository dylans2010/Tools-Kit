import Foundation

class SQLFormatterBackend: ObservableObject {
    @Published var inputText = ""
    @Published var outputText = ""

    func format() {
        let sql = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sql.isEmpty else {
            outputText = ""
            return
        }

        let keywords = ["SELECT", "FROM", "WHERE", "AND", "OR", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON", "GROUP", "BY", "ORDER", "HAVING", "LIMIT", "UPDATE", "SET", "DELETE", "INSERT", "INTO", "VALUES", "CREATE", "TABLE", "DROP", "ALTER"]

        var formatted = sql

        // Capitalize keywords
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                formatted = regex.stringByReplacingMatches(in: formatted, options: [], range: NSRange(location: 0, length: formatted.utf16.count), withTemplate: keyword.uppercased())
            }
        }

        // Add newlines before major keywords
        let newlineKeywords = ["SELECT", "FROM", "WHERE", "JOIN", "LEFT", "RIGHT", "GROUP", "BY", "ORDER", "HAVING", "LIMIT", "SET", "VALUES"]
        for keyword in newlineKeywords {
            formatted = formatted.replacingOccurrences(of: " \(keyword) ", with: "\n\(keyword) ")
            formatted = formatted.replacingOccurrences(of: " \(keyword)", with: "\n\(keyword)")
        }

        outputText = formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
