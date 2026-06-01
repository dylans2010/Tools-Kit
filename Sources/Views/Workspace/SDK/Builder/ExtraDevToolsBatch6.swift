import SwiftUI

// MARK: - Extra Tools Batch 6

struct URITemplateTesterDevTool: DevTool {
    let id = "uri-template-tester"
    let name = "URI Template Tester"
    let category: DevToolCategory = .networking
    let icon = "link.badge.plus"
    let description = "Test RFC 6570 URI Templates with variables"
    func render() -> some View { URITemplateTesterView() }
}

struct URITemplateTesterView: View {
    @State private var template = "https://api.example.com/{user}/posts{?limit,offset}"
    @State private var variables = "user=jules\nlimit=10\noffset=0"
    @State private var result = ""

    var body: some View {
        Form {
            Section("URI Template") {
                TextField("Template", text: $template)
            }
            Section("Variables (key=value)") {
                TextEditor(text: $variables).frame(height: 100)
            }
            Button("Expand Template") {
                var expanded = template
                let pairs = variables.components(separatedBy: .newlines)
                for pair in pairs {
                    let parts = pair.components(separatedBy: "=")
                    if parts.count == 2 {
                        let key = parts[0].trimmingCharacters(in: .whitespaces)
                        let val = parts[1].trimmingCharacters(in: .whitespaces)
                        // Simple expansion logic
                        expanded = expanded.replacingOccurrences(of: "{\(key)}", with: val)
                        expanded = expanded.replacingOccurrences(of: "{\(key)*}", with: val)

                        // Query param expansion (simplified)
                        if expanded.contains("{?") {
                            if expanded.contains(key) {
                                let prefix = expanded.contains("?") ? "&" : "?"
                                expanded = expanded.replacingOccurrences(of: "{?\(key)}", with: "\(prefix)\(key)=\(val)")
                                expanded = expanded.replacingOccurrences(of: ",\(key)}", with: "&\(key)=\(val)}")
                                expanded = expanded.replacingOccurrences(of: "{?\(key),", with: "?\(key)=\(val),")
                            }
                        }
                    }
                }
                // Clean up remaining template markers
                expanded = expanded.replacingOccurrences(of: #"\{.*?\}"#, with: "", options: .regularExpression)
                result = expanded
            }.buttonStyle(.borderedProminent)

            if !result.isEmpty {
                Section("Result") {
                    Text(result).textSelection(.enabled)
                }
            }
        }
    }
}

struct MarkdownTableGeneratorDevTool: DevTool {
    let id = "md-table-gen"
    let name = "Markdown Table Gen"
    let category: DevToolCategory = .utilities
    let icon = "table.fill"
    let description = "Generate Markdown tables from CSV text"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Header1,Header2\nValue1,Value2") { input in
        let lines = input.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard let header = lines.first else { return "" }
        let columns = header.components(separatedBy: ",")
        let separator = "|" + columns.map { _ in " --- " }.joined(separator: "|") + "|"
        let headerRow = "|" + columns.map { " \($0.trimmingCharacters(in: .whitespaces)) " }.joined(separator: "|") + "|"
        let body = lines.dropFirst().map { line in
            "|" + line.components(separatedBy: ",").map { " \($0.trimmingCharacters(in: .whitespaces)) " }.joined(separator: "|") + "|"
        }.joined(separator: "\n")
        return headerRow + "\n" + separator + "\n" + body
    }}
}

struct JSONStringifierDevTool: DevTool {
    let id = "json-stringify"
    let name = "JSON Stringifier"
    let category: DevToolCategory = .data
    let icon = "quote.bubble"
    let description = "Convert JSON to a stringified JS-safe format"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "{\"key\": \"value\"}") { input in
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: []),
              let str = String(data: prettyData, encoding: .utf8) else { return "Invalid JSON" }
        return str.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "")
    }}
}

struct HTMLEntityListDevTool: DevTool {
    let id = "html-entity-list"
    let name = "HTML Entity List"
    let category: DevToolCategory = .uiDesign
    let icon = "list.dash"
    let description = "Reference for common HTML character entities"
    func render() -> some View { HTMLEntityListView() }
}

struct HTMLEntityListView: View {
    @State private var search = ""
    let entities = [
        ("&nbsp;", "Non-breaking space"), ("&lt;", "Less than"), ("&gt;", "Greater than"),
        ("&amp;", "Ampersand"), ("&quot;", "Quotation mark"), ("&apos;", "Apostrophe"),
        ("&copy;", "Copyright"), ("&reg;", "Registered trademark"), ("&trade;", "Trademark"),
        ("&euro;", "Euro sign"), ("&pound;", "Pound sign"), ("&yen;", "Yen sign"),
        ("&deg;", "Degree sign"), ("&plusmn;", "Plus-minus sign"), ("&times;", "Multiplication sign"),
        ("&divide;", "Division sign"), ("&micro;", "Micro sign"), ("&para;", "Paragraph sign"),
        ("&middot;", "Middle dot"), ("&hellip;", "Horizontal ellipsis")
    ]

    var filteredEntities: [(String, String)] {
        if search.isEmpty { return entities }
        return entities.filter { $0.0.localizedCaseInsensitiveContains(search) || $0.1.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack {
            TextField("Search entities...", text: $search).textFieldStyle(.roundedBorder).padding()
            List(filteredEntities, id: \.0) { entity in
                HStack {
                    Text(entity.0).font(.system(.body, design: .monospaced)).bold()
                    Spacer()
                    Text(entity.1).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ColorContrastRatioDevTool: DevTool {
    let id = "contrast-ratio"
    let name = "Contrast Ratio Calc"
    let category: DevToolCategory = .uiDesign
    let icon = "circle.lefthalf.filled"
    let description = "Calculate contrast ratio between two colors (WCAG)"
    func render() -> some View { ColorContrastRatioView() }
}

struct ColorContrastRatioView: View {
    @State private var color1 = Color.white
    @State private var color2 = Color.black

    var contrastRatio: Double {
        let l1 = relativeLuminance(color1)
        let l2 = relativeLuminance(color2)
        let brighter = max(l1, l2)
        let darker = min(l1, l2)
        return (brighter + 0.05) / (darker + 0.05)
    }

    var body: some View {
        Form {
            Section("Colors") {
                ColorPicker("Background", selection: $color1)
                ColorPicker("Foreground", selection: $color2)
            }
            Section("Result") {
                HStack {
                    Text("Contrast Ratio")
                    Spacer()
                    Text(String(format: "%.2f:1", contrastRatio)).bold()
                }
                Text(contrastRatio >= 4.5 ? "✅ Passes AA (4.5:1)" : "❌ Fails AA")
                Text(contrastRatio >= 7.0 ? "✅ Passes AAA (7.0:1)" : "❌ Fails AAA")
            }
        }
    }

    private func relativeLuminance(_ color: Color) -> Double {
        let components = color.getComponents()
        func adjust(_ val: CGFloat) -> Double {
            let v = Double(val)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * adjust(components.r) + 0.7152 * adjust(components.g) + 0.0722 * adjust(components.b)
    }
}

struct FileExtensionInspectorDevTool: DevTool {
    let id = "file-ext-inspector"
    let name = "File Ext Inspector"
    let category: DevToolCategory = .system
    let icon = "doc.questionmark"
    let description = "Lookup common file extensions and their MIME types"
    func render() -> some View { FileExtensionInspectorView() }
}

struct FileExtensionInspectorView: View {
    @State private var search = ""
    let extensions = [
        (".jpg", "image/jpeg"), (".png", "image/png"), (".gif", "image/gif"), (".webp", "image/webp"),
        (".json", "application/json"), (".pdf", "application/pdf"), (".xml", "application/xml"),
        (".zip", "application/zip"), (".mp3", "audio/mpeg"), (".mp4", "video/mp4"),
        (".html", "text/html"), (".css", "text/css"), (".js", "text/javascript"), (".csv", "text/csv")
    ]

    var filtered: [(String, String)] {
        if search.isEmpty { return extensions }
        return extensions.filter { $0.0.localizedCaseInsensitiveContains(search) || $0.1.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack {
            TextField("Search extensions...", text: $search).textFieldStyle(.roundedBorder).padding()
            List(filtered, id: \.0) { item in
                HStack {
                    Text(item.0).bold()
                    Spacer()
                    Text(item.1).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct StringLengthStatsDevTool: DevTool {
    let id = "str-stats"
    let name = "String Stats"
    let category: DevToolCategory = .utilities
    let icon = "textformat.123"
    let description = "Detailed statistics for a string (bytes, runes, etc.)"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text") { input in
        let bytes = input.data(using: .utf8)?.count ?? 0
        let words = input.split(separator: .whitespacesAndNewlines).count
        let lines = input.components(separatedBy: .newlines).count
        let runes = input.unicodeScalars.count
        return "Characters: \(input.count)\nRunes: \(runes)\nBytes: \(bytes)\nWords: \(words)\nLines: \(lines)"
    }}
}

struct Base64URLConverterDevTool: DevTool {
    let id = "b64url-converter"
    let name = "Base64URL Converter"
    let category: DevToolCategory = .encoding
    let icon = "link.badge.plus.fill"
    let description = "Convert between Base64 and Base64URL"
    func render() -> some View { Base64URLConverterView() }
}

struct Base64URLConverterView: View {
    @State private var input = ""
    @State private var result = ""
    @State private var toURL = true

    var body: some View {
        Form {
            Section("Mode") {
                Picker("Direction", selection: $toURL) {
                    Text("Base64 to URL").tag(true)
                    Text("URL to Base64").tag(false)
                }.pickerStyle(.segmented)
            }
            Section("Input") {
                TextEditor(text: $input).frame(height: 100)
            }
            Button("Convert") {
                if toURL {
                    result = input.replacingOccurrences(of: "+", with: "-")
                                  .replacingOccurrences(of: "/", with: "_")
                                  .replacingOccurrences(of: "=", with: "")
                } else {
                    var base64 = input.replacingOccurrences(of: "-", with: "+")
                                      .replacingOccurrences(of: "_", with: "/")
                    while base64.count % 4 != 0 { base64.append("=") }
                    result = base64
                }
            }.buttonStyle(.borderedProminent)
            if !result.isEmpty {
                Section("Output") {
                    Text(result).textSelection(.enabled)
                }
            }
        }
    }
}

struct HTTPStatusRefDevTool: DevTool {
    let id = "http-status-ref"
    let name = "HTTP Status Ref"
    let category: DevToolCategory = .networking
    let icon = "exclamationmark.circle"
    let description = "Reference for HTTP status codes"
    func render() -> some View { HTTPStatusRefView() }
}

struct HTTPStatusRefView: View {
    @State private var search = ""
    let codes = [
        ("100", "Continue"), ("101", "Switching Protocols"),
        ("200", "OK"), ("201", "Created"), ("202", "Accepted"), ("204", "No Content"),
        ("301", "Moved Permanently"), ("302", "Found"), ("304", "Not Modified"),
        ("400", "Bad Request"), ("401", "Unauthorized"), ("403", "Forbidden"), ("404", "Not Found"), ("405", "Method Not Allowed"), ("409", "Conflict"), ("429", "Too Many Requests"),
        ("500", "Internal Server Error"), ("501", "Not Implemented"), ("502", "Bad Gateway"), ("503", "Service Unavailable"), ("504", "Gateway Timeout")
    ]

    var filtered: [(String, String)] {
        if search.isEmpty { return codes }
        return codes.filter { $0.0.contains(search) || $0.1.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack {
            TextField("Enter code or name...", text: $search).textFieldStyle(.roundedBorder).padding()
            List(filtered, id: \.0) { item in
                HStack {
                    Text(item.0).bold()
                    Spacer()
                    Text(item.1).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct LoremIpsumBatchDevTool: DevTool {
    let id = "lorem-batch"
    let name = "Lorem Ipsum Batch"
    let category: DevToolCategory = .utilities
    let icon = "doc.on.doc"
    let description = "Generate multiple paragraphs of Lorem Ipsum"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Number of paragraphs") { input in
        let count = Int(input) ?? 3
        let paragraphs = (0..<min(count, 50)).map { _ in "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur." }
        return paragraphs.joined(separator: "\n\n")
    }}
}
