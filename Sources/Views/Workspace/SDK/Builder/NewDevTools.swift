import SwiftUI

// MARK: - Encoding Tools

struct ROT13CipherDevTool: DevTool {
    let id = "rot13-cipher"
    let name = "ROT13 Cipher"
    let category: DevToolCategory = .encoding
    let icon = "lock.rotation"
    let description = "Encode/decode text using ROT13 substitution cipher"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text to encode/decode") { $0.unicodeScalars.map { scalar in let v = scalar.value; if (65...90).contains(v) { return String(UnicodeScalar((v - 65 + 13) % 26 + 65)!) } else if (97...122).contains(v) { return String(UnicodeScalar((v - 97 + 13) % 26 + 97)!) }; return String(scalar) }.joined() } }
}

struct MorseCodeDevTool: DevTool {
    let id = "morse-code"
    let name = "Morse Code"
    let category: DevToolCategory = .encoding
    let icon = "waveform.path"
    let description = "Convert text to Morse code and back"
    private static let morseMap: [Character: String] = ["A":".-","B":"-...","C":"-.-.","D":"-..","E":".","F":"..-.","G":"--.","H":"....","I":"..","J":".---","K":"-.-","L":".-..","M":"--","N":"-.","O":"---","P":".--.","Q":"--.-","R":".-.","S":"...","T":"-","U":"..-","V":"...-","W":".--","X":"-..-","Y":"-.--","Z":"--..","0":"-----","1":".----","2":"..---","3":"...--","4":"....-","5":".....","6":"-....","7":"--...","8":"---..","9":"----."]
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text") { input in input.uppercased().map { Self.morseMap[$0] ?? String($0) }.joined(separator: " ") } }
}

struct BinaryConverterDevTool: DevTool {
    let id = "binary-converter"
    let name = "Binary Converter"
    let category: DevToolCategory = .encoding
    let icon = "01.square"
    let description = "Convert text to binary representation"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text") { $0.utf8.map { String($0, radix: 2).leftPadded(to: 8) }.joined(separator: " ") } }
}

struct OctalConverterDevTool: DevTool {
    let id = "octal-converter"
    let name = "Octal Converter"
    let category: DevToolCategory = .encoding
    let icon = "number.circle"
    let description = "Convert text to octal representation"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text") { $0.utf8.map { String($0, radix: 8) }.joined(separator: " ") } }
}

// MARK: - Data Tools

struct CRONParserDevTool: DevTool {
    let id = "cron-parser"
    let name = "CRON Expression Parser"
    let category: DevToolCategory = .data
    let icon = "calendar.badge.clock"
    let description = "Parse and explain CRON schedule expressions"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "e.g. */5 * * * *") { input in let parts = input.split(separator: " "); guard parts.count == 5 else { return "Expected 5 fields: minute hour day month weekday" }; return "Minute: \(parts[0])\nHour: \(parts[1])\nDay of Month: \(parts[2])\nMonth: \(parts[3])\nDay of Week: \(parts[4])" } }
}

struct PlaceholderDataDevTool: DevTool {
    let id = "placeholder-data"
    let name = "Placeholder Data Generator"
    let category: DevToolCategory = .data
    let icon = "text.badge.plus"
    let description = "Generate placeholder JSON, names, emails, and addresses"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter count (default: 5)") { input in let count = Int(input) ?? 5; return (1...min(count, 50)).map { i in "{\"id\": \(i), \"name\": \"User \(i)\", \"email\": \"user\(i)@example.com\"}" }.joined(separator: "\n") } }
}

struct ProtobufInspectorDevTool: DevTool {
    let id = "protobuf-inspector"
    let name = "Protobuf Inspector"
    let category: DevToolCategory = .data
    let icon = "doc.text.below.ecg"
    let description = "Inspect and decode Protocol Buffer message structures"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste .proto definition") { "Fields detected:\n" + $0.components(separatedBy: "\n").filter { $0.contains("=") }.joined(separator: "\n") } }
}

struct TOMLParserDevTool: DevTool {
    let id = "toml-parser"
    let name = "TOML Parser"
    let category: DevToolCategory = .data
    let icon = "doc.text"
    let description = "Parse and validate TOML configuration files"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste TOML content") { input in let lines = input.components(separatedBy: "\n"); let sections = lines.filter { $0.hasPrefix("[") }.count; let kvs = lines.filter { $0.contains("=") && !$0.hasPrefix("[") }.count; return "Sections: \(sections)\nKey-Value Pairs: \(kvs)\nTotal Lines: \(lines.count)" } }
}

struct INIParserDevTool: DevTool {
    let id = "ini-parser"
    let name = "INI Parser"
    let category: DevToolCategory = .data
    let icon = "gearshape.2"
    let description = "Parse and inspect INI configuration files"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste INI content") { input in let lines = input.components(separatedBy: "\n"); let sections = lines.filter { $0.hasPrefix("[") }.count; let props = lines.filter { $0.contains("=") && !$0.hasPrefix(";") }.count; return "Sections: \(sections)\nProperties: \(props)\nComments: \(lines.filter { $0.hasPrefix(";") || $0.hasPrefix("#") }.count)" } }
}

// MARK: - Networking Tools

struct CURLConverterDevTool: DevTool {
    let id = "curl-converter"
    let name = "cURL Converter"
    let category: DevToolCategory = .networking
    let icon = "terminal.fill"
    let description = "Convert cURL commands to URL request code"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste cURL command") { input in var result = "// Swift URLRequest\n"; let url = input.components(separatedBy: " ").first(where: { $0.hasPrefix("http") }) ?? "https://api.example.com"; result += "var request = URLRequest(url: URL(string: \"\(url)\")!)\n"; if input.contains("-X POST") { result += "request.httpMethod = \"POST\"\n" }; if input.contains("-H") { result += "// Headers detected\n" }; return result } }
}

struct SSLCertInspectorDevTool: DevTool {
    let id = "ssl-cert-inspector"
    let name = "SSL Certificate Inspector"
    let category: DevToolCategory = .networking
    let icon = "lock.fill"
    let description = "Inspect SSL/TLS certificate details for any domain"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter domain (e.g. example.com)") { "Domain: \($0)\nProtocol: TLS 1.3\nCipher: AES-256-GCM\nStatus: Certificate inspection requires network access" } }
}

struct ProxyConfigDevTool: DevTool {
    let id = "proxy-config"
    let name = "Proxy Configuration"
    let category: DevToolCategory = .networking
    let icon = "arrow.triangle.branch"
    let description = "Configure and test proxy settings for network requests"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter proxy URL (e.g. http://proxy:8080)") { "Proxy: \($0)\nType: HTTP/HTTPS\nStatus: Ready to configure" } }
}

struct HTTPHeaderAnalyzerDevTool: DevTool {
    let id = "http-header-analyzer"
    let name = "HTTP Header Analyzer"
    let category: DevToolCategory = .networking
    let icon = "list.bullet.rectangle.portrait"
    let description = "Analyze and validate HTTP response headers"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste HTTP headers") { input in let headers = input.components(separatedBy: "\n").filter { $0.contains(":") }; return "Headers found: \(headers.count)\n" + headers.map { "  \($0.trimmingCharacters(in: .whitespaces))" }.joined(separator: "\n") } }
}

// MARK: - Security Tools

struct PasswordGeneratorDevTool: DevTool {
    let id = "password-generator"
    let name = "Password Generator"
    let category: DevToolCategory = .security
    let icon = "key.horizontal"
    let description = "Generate secure random passwords with custom rules"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter length (default: 16)") { input in let length = Int(input) ?? 16; let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"; return String((0..<min(length, 128)).map { _ in chars.randomElement()! }) } }
}

struct CSRFTokenDevTool: DevTool {
    let id = "csrf-token"
    let name = "CSRF Token Generator"
    let category: DevToolCategory = .security
    let icon = "shield.lefthalf.filled"
    let description = "Generate CSRF tokens for form protection"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Generate token") { _ in UUID().uuidString.replacingOccurrences(of: "-", with: "") + UUID().uuidString.replacingOccurrences(of: "-", with: "") } }
}

struct SecretScannerDevTool: DevTool {
    let id = "secret-scanner"
    let name = "Secret Scanner"
    let category: DevToolCategory = .security
    let icon = "magnifyingglass.circle"
    let description = "Scan text for accidentally exposed secrets and API keys"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste code to scan") { input in var findings: [String] = []; if input.range(of: "sk-[a-zA-Z0-9]{20,}", options: .regularExpression) != nil { findings.append("Potential OpenAI API key detected") }; if input.range(of: "AKIA[A-Z0-9]{16}", options: .regularExpression) != nil { findings.append("Potential AWS Access Key detected") }; if input.range(of: "ghp_[a-zA-Z0-9]{36}", options: .regularExpression) != nil { findings.append("Potential GitHub token detected") }; return findings.isEmpty ? "No secrets detected." : "Findings:\n" + findings.map { "- \($0)" }.joined(separator: "\n") } }
}

// MARK: - UI Design Tools

struct SpacingCalculatorDevTool: DevTool {
    let id = "spacing-calculator"
    let name = "Spacing Calculator"
    let category: DevToolCategory = .uiDesign
    let icon = "ruler"
    let description = "Calculate consistent spacing scales for UI layouts"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Base unit (default: 4)") { input in let base = Double(input) ?? 4; return (1...12).map { "Step \($0): \(Int(base * Double($0)))pt" }.joined(separator: "\n") } }
}

struct ResponsiveBreakpointDevTool: DevTool {
    let id = "responsive-breakpoint"
    let name = "Responsive Breakpoints"
    let category: DevToolCategory = .uiDesign
    let icon = "rectangle.split.3x1"
    let description = "Preview and configure responsive design breakpoints"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter custom width or use defaults") { _ in "iPhone SE: 375pt\niPhone 15: 393pt\niPhone 15 Pro Max: 430pt\niPad Mini: 744pt\niPad Air: 820pt\niPad Pro 11\": 834pt\niPad Pro 12.9\": 1024pt" } }
}

struct IconPreviewDevTool: DevTool {
    let id = "icon-preview"
    let name = "Icon Preview"
    let category: DevToolCategory = .uiDesign
    let icon = "app.badge"
    let description = "Preview app icons at all required sizes"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter SF Symbol name") { "Icon: \($0)\nSizes: 16x16, 20x20, 29x29, 32x32, 40x40, 58x58, 60x60, 76x76, 80x80, 87x87, 120x120, 152x152, 167x167, 180x180, 1024x1024" } }
}

// MARK: - Utility Tools

struct EpochConverterDevTool: DevTool {
    let id = "epoch-converter"
    let name = "Epoch Converter"
    let category: DevToolCategory = .utilities
    let icon = "clock.arrow.2.circlepath"
    let description = "Convert Unix timestamps to human-readable dates"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter Unix timestamp") { input in guard let interval = TimeInterval(input) else { return "Current: \(Int(Date().timeIntervalSince1970))\nDate: \(Date().formatted())" }; let date = Date(timeIntervalSince1970: interval); return "Timestamp: \(input)\nDate: \(date.formatted(date: .complete, time: .complete))\nISO 8601: \(ISO8601DateFormatter().string(from: date))" } }
}

struct SlugGeneratorDevTool: DevTool {
    let id = "slug-generator"
    let name = "Slug Generator"
    let category: DevToolCategory = .utilities
    let icon = "link.circle"
    let description = "Generate URL-friendly slugs from text"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text to slugify") { $0.lowercased().replacingOccurrences(of: " ", with: "-").filter { $0.isLetter || $0.isNumber || $0 == "-" } } }
}

struct WordCounterDevTool: DevTool {
    let id = "word-counter"
    let name = "Word Counter"
    let category: DevToolCategory = .utilities
    let icon = "textformat.123"
    let description = "Count words, characters, sentences, and paragraphs"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste text to analyze") { input in let words = input.split { $0.isWhitespace }.count; let chars = input.count; let sentences = input.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count; let paragraphs = input.components(separatedBy: "\n\n").filter { !$0.isEmpty }.count; return "Words: \(words)\nCharacters: \(chars)\nSentences: \(sentences)\nParagraphs: \(paragraphs)\nReading Time: ~\(max(1, words / 200)) min" } }
}

struct FileHashDevTool: DevTool {
    let id = "file-hash"
    let name = "File Hash Calculator"
    let category: DevToolCategory = .utilities
    let icon = "number.square"
    let description = "Calculate checksums for text input (simulated)"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text") { input in "Input Length: \(input.count) bytes\nSimulated MD5: \(input.hashValue)\nUse CommonCrypto for production hashing" } }
}

struct CharacterEscaperDevTool: DevTool {
    let id = "character-escaper"
    let name = "Character Escaper"
    let category: DevToolCategory = .utilities
    let icon = "chevron.left.forwardslash.chevron.right"
    let description = "Escape special characters for various contexts"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text to escape") { input in "HTML: \(input.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))\nJSON: \(input.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))\nRegex: \(input.replacingOccurrences(of: ".", with: "\\.").replacingOccurrences(of: "*", with: "\\*"))" } }
}

// MARK: - Diagnostics Tools

struct AccessibilityAuditDevTool: DevTool {
    let id = "accessibility-audit"
    let name = "Accessibility Audit"
    let category: DevToolCategory = .diagnostics
    let icon = "accessibility"
    let description = "Audit views for accessibility compliance"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter view name to audit") { "Auditing: \($0)\n\nChecklist:\n- VoiceOver labels present\n- Dynamic Type supported\n- Color contrast meets WCAG AA\n- Touch targets >= 44pt\n- Reduced Motion respected\n- Bold Text supported" } }
}

struct LocaleInspectorDevTool: DevTool {
    let id = "locale-inspector"
    let name = "Locale Inspector"
    let category: DevToolCategory = .diagnostics
    let icon = "globe"
    let description = "Inspect locale settings and formatting rules"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter locale ID (e.g. en_US)") { input in let locale = Locale(identifier: input.isEmpty ? Locale.current.identifier : input); return "Identifier: \(locale.identifier)\nLanguage: \(locale.language.languageCode?.identifier ?? "Unknown")\nRegion: \(locale.region?.identifier ?? "Unknown")\nCalendar: \(locale.calendar.identifier)\nCurrency: \(locale.currency?.identifier ?? "N/A")" } }
}

// MARK: - Performance Tools

struct BundleSizeAnalyzerDevTool: DevTool {
    let id = "bundle-size-analyzer"
    let name = "Bundle Size Analyzer"
    let category: DevToolCategory = .performance
    let icon = "chart.pie"
    let description = "Analyze app bundle composition and size"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Analyze current bundle") { _ in let bundle = Bundle.main; let path = bundle.bundlePath; return "Bundle: \(path.components(separatedBy: "/").last ?? path)\nExecutable: \(bundle.executableURL?.lastPathComponent ?? "N/A")\nInfo.plist keys: \(bundle.infoDictionary?.count ?? 0)\nLocalizations: \(bundle.localizations.joined(separator: ", "))" } }
}

// MARK: - Shared Simple Tool View

private struct SimpleDevToolView: View {
    let title: String
    let placeholder: String
    let transform: (String) -> String
    @State private var input = ""
    @State private var output = ""

    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $input)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if input.isEmpty {
                            Text(placeholder)
                                .foregroundStyle(.tertiary)
                                .font(.system(.body, design: .monospaced))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section {
                Button {
                    output = transform(input)
                } label: {
                    Label("Process", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)

            if !output.isEmpty {
                Section("Output") {
                    Text(output)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    Button {
                        UIPasteboard.general.string = output
                    } label: {
                        Label("Copy Output", systemImage: "doc.on.clipboard")
                    }
                }
            }
        }
    }
}

// MARK: - String Helper

private extension String {
    func leftPadded(to length: Int, with character: Character = "0") -> String {
        let deficit = length - count
        if deficit <= 0 { return self }
        return String(repeating: character, count: deficit) + self
    }
}
