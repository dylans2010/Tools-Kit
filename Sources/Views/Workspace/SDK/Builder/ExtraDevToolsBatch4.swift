import SwiftUI

// MARK: - Networking & Utility Tools

struct MACAddressGenDevTool: DevTool {
    let id = "mac-gen"
    let name = "MAC Address Gen"
    let category: DevToolCategory = .networking
    let icon = "network.badge.shield.half.filled"
    let description = "Generate random MAC addresses"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Count (default 5)") { input in
        let count = Int(input) ?? 5
        let hex = "0123456789ABCDEF"
        return (0..<min(count, 50)).map { _ in
            (0..<6).map { _ in String((0..<2).map { _ in hex.randomElement()! }) }.joined(separator: ":")
        }.joined(separator: "\n")
    }}
}

struct IPv6AddressGenDevTool: DevTool {
    let id = "ipv6-gen"
    let name = "IPv6 Address Gen"
    let category: DevToolCategory = .networking
    let icon = "lanconnect"
    let description = "Generate random IPv6 addresses"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Count (default 5)") { input in
        let count = Int(input) ?? 5
        let hex = "0123456789abcdef"
        return (0..<min(count, 50)).map { _ in
            (0..<8).map { _ in String((0..<4).map { _ in hex.randomElement()! }) }.joined(separator: ":")
        }.joined(separator: "\n")
    }}
}

struct URLSplitterDevTool: DevTool {
    let id = "url-splitter"
    let name = "URL Splitter"
    let category: DevToolCategory = .networking
    let icon = "arrow.up.right.and.arrow.down.left.rectangle"
    let description = "Break down a URL into its components"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "https://example.com/path?q=1") { input in
        guard let url = URL(string: input), let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return "Invalid URL" }
        return "Scheme: \(comps.scheme ?? "")\nHost: \(comps.host ?? "")\nPath: \(comps.path)\nQuery: \(comps.query ?? "")\nFragment: \(comps.fragment ?? "")"
    }}
}

struct UnitConverterDevTool: DevTool {
    let id = "unit-converter"
    let name = "Unit Converter"
    let category: DevToolCategory = .utilities
    let icon = "scalemass"
    let description = "Convert between common units of measurement"
    func render() -> some View { UnitConverterView() }
}

struct UnitConverterView: View {
    @State private var value = "1"
    @State private var from = "KM"
    @State private var to = "Miles"
    var body: some View {
        Form {
            TextField("Value", text: $value).keyboardType(.decimalPad)
            HStack {
                Picker("From", selection: $from) { Text("KM").tag("KM"); Text("Miles").tag("Miles") }
                Image(systemName: "arrow.right")
                Picker("To", selection: $to) { Text("KM").tag("KM"); Text("Miles").tag("Miles") }
            }
            if let v = Double(value) {
                Section("Result") {
                    if from == "KM" && to == "Miles" { Text("\(v * 0.621371) Miles") }
                    else if from == "Miles" && to == "KM" { Text("\(v * 1.60934) KM") }
                    else { Text("\(v)") }
                }
            }
        }
    }
}

struct LineSorterDevTool: DevTool {
    let id = "line-sorter"
    let name = "Line Sorter"
    let category: DevToolCategory = .utilities
    let icon = "arrow.up.arrow.down.square"
    let description = "Sort lines of text alphabetically"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste lines to sort") { input in
        input.components(separatedBy: "\n").sorted().joined(separator: "\n")
    }}
}

struct DuplicateRemoverDevTool: DevTool {
    let id = "duplicate-remover"
    let name = "Duplicate Remover"
    let category: DevToolCategory = .utilities
    let icon = "minus.square.fill"
    let description = "Remove duplicate lines from text"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste lines with duplicates") { input in
        let lines = input.components(separatedBy: "\n")
        var seen = Set<String>()
        return lines.filter { seen.insert($0).inserted }.joined(separator: "\n")
    }}
}

struct StringReverserDevTool: DevTool {
    let id = "string-reverser"
    let name = "String Reverser"
    let category: DevToolCategory = .utilities
    let icon = "arrow.left.square.fill"
    let description = "Reverse the order of characters in a string"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Text to reverse") { String($0.reversed()) }}
}

struct MarkdownToHTMLDevTool: DevTool {
    let id = "md-to-html"
    let name = "Markdown to HTML"
    let category: DevToolCategory = .utilities
    let icon = "chevron.left.forwardslash.chevron.right"
    let description = "Simple Markdown to HTML converter"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "# Hello\n**bold**") { input in
        input.replacingOccurrences(of: "^# (.*)", with: "<h1>$1</h1>", options: .regularExpression)
            .replacingOccurrences(of: "\\*\\*(.*)\\*\\*", with: "<b>$1</b>", options: .regularExpression)
    }}
}

struct HTMLToMarkdownDevTool: DevTool {
    let id = "html-to-md"
    let name = "HTML to Markdown"
    let category: DevToolCategory = .utilities
    let icon = "m.circle"
    let description = "Convert HTML tags back to Markdown"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "<h1>Title</h1>") { input in
        input.replacingOccurrences(of: "<h1>(.*)</h1>", with: "# $1", options: .regularExpression)
            .replacingOccurrences(of: "<b>(.*)</b>", with: "**$1**", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }}
}

struct WordCloudDevTool: DevTool {
    let id = "word-cloud"
    let name = "Word Cloud Data"
    let category: DevToolCategory = .utilities
    let icon = "cloud.fill"
    let description = "Calculate word frequency for cloud visualization"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste long text") { input in
        let words = input.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { $0.count > 3 }
        var counts: [String: Int] = [:]
        words.forEach { counts[$0, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }.prefix(20).map { "\($0.key): \($0.value)" }.joined(separator: "\n")
    }}
}
