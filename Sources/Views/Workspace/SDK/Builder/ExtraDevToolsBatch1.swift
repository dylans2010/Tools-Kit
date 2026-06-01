import SwiftUI

// MARK: - Data Processing Tools

struct JSONMinifierDevTool: DevTool {
    let id = "json-minifier"
    let name = "JSON Minifier"
    let category: DevToolCategory = .data
    let icon = "arrow.right.to.line.compact"
    let description = "Minify JSON by removing whitespace and newlines"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste JSON to minify") { input in
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let minifiedData = try? JSONSerialization.data(withJSONObject: json, options: []),
              let result = String(data: minifiedData, encoding: .utf8) else { return "Invalid JSON" }
        return result
    }}
}

struct XMLMinifierDevTool: DevTool {
    let id = "xml-minifier"
    let name = "XML Minifier"
    let category: DevToolCategory = .data
    let icon = "doc.text.below.ecg.fill"
    let description = "Remove whitespace and comments from XML"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste XML to minify") { input in
        input.replacingOccurrences(of: ">\\s+<", with: "><", options: .regularExpression)
            .replacingOccurrences(of: "<!--.*?-->", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }}
}

struct SQLFormatterDevTool: DevTool {
    let id = "sql-formatter"
    let name = "SQL Formatter"
    let category: DevToolCategory = .data
    let icon = "m.square.fill"
    let description = "Format SQL queries for better readability"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "SELECT * FROM users WHERE id = 1") { input in
        let keywords = ["SELECT", "FROM", "WHERE", "JOIN", "LEFT JOIN", "RIGHT JOIN", "GROUP BY", "ORDER BY", "HAVING", "LIMIT", "INSERT INTO", "UPDATE", "DELETE", "SET", "VALUES", "AND", "OR"]
        var formatted = input.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        for keyword in keywords {
            formatted = formatted.replacingOccurrences(of: "\\b\(keyword)\\b", with: "\n" + keyword, options: [.caseInsensitive, .regularExpression])
        }
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }}
}

struct JSFormatterDevTool: DevTool {
    let id = "js-formatter"
    let name = "JS Formatter"
    let category: DevToolCategory = .data
    let icon = "js.square.fill"
    let description = "Basic JavaScript code formatting"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "function test(){console.log('hi');}") { input in
        var result = ""
        var indent = 0
        for char in input {
            if char == "{" {
                indent += 1
                result += " {\n" + String(repeating: "  ", count: indent)
            } else if char == "}" {
                indent = max(0, indent - 1)
                result += "\n" + String(repeating: "  ", count: indent) + "}"
            } else if char == ";" {
                result += ";\n" + String(repeating: "  ", count: indent)
            } else {
                result.append(char)
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }}
}

struct CSSFormatterDevTool: DevTool {
    let id = "css-formatter"
    let name = "CSS Formatter"
    let category: DevToolCategory = .data
    let icon = "c.square.fill"
    let description = "Format CSS rules with proper indentation"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "body{color:red;margin:0;}") { input in
        var result = ""
        var indent = 0
        for char in input {
            if char == "{" {
                indent += 1
                result += " {\n" + String(repeating: "  ", count: indent)
            } else if char == "}" {
                indent = max(0, indent - 1)
                result += "\n" + String(repeating: "  ", count: indent) + "}"
            } else if char == ";" {
                result += ";\n" + String(repeating: "  ", count: indent)
            } else if char == ":" {
                result += ": "
            } else {
                result.append(char)
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }}
}

struct Base64ToHexDevTool: DevTool {
    let id = "b64-to-hex"
    let name = "Base64 to Hex"
    let category: DevToolCategory = .data
    let icon = "hexagons.fill"
    let description = "Convert Base64 string to Hexadecimal"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter Base64") { input in
        guard let data = Data(base64Encoded: input) else { return "Invalid Base64" }
        return data.map { String(format: "%02x", $0) }.joined()
    }}
}

struct HexToBase64DevTool: DevTool {
    let id = "hex-to-b64"
    let name = "Hex to Base64"
    let category: DevToolCategory = .data
    let icon = "square.stack.3d.up.fill"
    let description = "Convert Hexadecimal to Base64 string"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter Hex") { input in
        var hex = input.replacingOccurrences(of: " ", with: "")
        if hex.count % 2 != 0 { hex = "0" + hex }
        var data = Data()
        for i in stride(from: 0, to: hex.count, by: 2) {
            let start = hex.index(hex.startIndex, offsetBy: i)
            let end = hex.index(start, offsetBy: 2)
            if let byte = UInt8(hex[start..<end], radix: 16) {
                data.append(byte)
            }
        }
        return data.base64EncodedString()
    }}
}

struct CSVToJSONDevTool: DevTool {
    let id = "csv-to-json"
    let name = "CSV to JSON"
    let category: DevToolCategory = .data
    let icon = "tablecells"
    let description = "Convert CSV data to a JSON array of objects"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "id,name\n1,John\n2,Jane") { input in
        let lines = input.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count > 1 else { return "[]" }
        let headers = lines[0].components(separatedBy: ",")
        var results: [[String: String]] = []
        for i in 1..<lines.count {
            let values = lines[i].components(separatedBy: ",")
            if values.count == headers.count {
                var dict: [String: String] = [:]
                for j in 0..<headers.count {
                    dict[headers[j]] = values[j]
                }
                results.append(dict)
            }
        }
        if let data = try? JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "Error converting CSV"
    }}
}

struct JSONToCSVDevTool: DevTool {
    let id = "json-to-csv"
    let name = "JSON to CSV"
    let category: DevToolCategory = .data
    let icon = "list.bullet.indent"
    let description = "Convert JSON array to CSV format"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "[{\"id\": 1, \"name\": \"John\"}]") { input in
        guard let data = input.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let first = array.first else { return "Invalid JSON Array" }
        let headers = first.keys.sorted()
        let headerRow = headers.joined(separator: ",")
        let rows = array.map { dict in
            headers.map { "\(dict[$0] ?? "")" }.joined(separator: ",")
        }.joined(separator: "\n")
        return headerRow + "\n" + rows
    }}
}

struct NanoIDGeneratorDevTool: DevTool {
    let id = "nanoid-generator"
    let name = "NanoID Generator"
    let category: DevToolCategory = .data
    let icon = "tag"
    let description = "Generate secure, URL-friendly unique IDs"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter count (default 10)") { input in
        let count = Int(input) ?? 10
        let alphabet = "useyouralphabetit789safehighqualityrandom0123456BCDFGHJKLMNPQRSTVWXYZ"
        return (0..<min(count, 100)).map { _ in
            String((0..<21).map { _ in alphabet.randomElement()! })
        }.joined(separator: "\n")
    }}
}

struct ULIDGeneratorDevTool: DevTool {
    let id = "ulid-generator"
    let name = "ULID Generator"
    let category: DevToolCategory = .data
    let icon = "clock.badge.checkmark"
    let description = "Generate Universally Unique Lexicographically Sortable Identifiers"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter count (default 10)") { input in
        let count = Int(input) ?? 10
        let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        return (0..<min(count, 100)).map { _ in
            let timestamp = String((0..<10).map { _ in alphabet.randomElement()! })
            let random = String((0..<16).map { _ in alphabet.randomElement()! })
            return timestamp + random
        }.joined(separator: "\n")
    }}
}
