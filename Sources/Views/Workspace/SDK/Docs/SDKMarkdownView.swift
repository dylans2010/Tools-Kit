import SwiftUI

/// Native SwiftUI Markdown renderer that parses raw Markdown text into formatted output.
/// Strips raw Markdown syntax characters and preserves structure (headings, lists, code blocks, tables).
struct SDKMarkdownView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseBlocks(text).enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
    }

    // MARK: - Block Types

    private enum MarkdownBlock {
        case heading(level: Int, text: String)
        case codeBlock(language: String, code: String)
        case unorderedListItem(depth: Int, text: String)
        case orderedListItem(number: String, text: String)
        case tableBlock(headers: [String], rows: [[String]])
        case paragraph(text: String)
        case horizontalRule
    }

    // MARK: - Parsing

    private func parseBlocks(_ input: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = input.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                i += 1
                continue
            }

            if trimmed.hasPrefix("```") {
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(language: lang, code: codeLines.joined(separator: "\n")))
                i += 1
                continue
            }

            if trimmed.allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" }) && trimmed.count >= 3 {
                blocks.append(.horizontalRule)
                i += 1
                continue
            }

            if trimmed.hasPrefix("#") {
                let level = trimmed.prefix(while: { $0 == "#" }).count
                let headingText = String(trimmed.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: min(level, 6), text: headingText))
                i += 1
                continue
            }

            if trimmed.contains("|") && i + 1 < lines.count {
                let nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if nextLine.contains("---") && nextLine.contains("|") {
                    let headers = parsePipeRow(trimmed)
                    var rows: [[String]] = []
                    i += 2
                    while i < lines.count {
                        let rowLine = lines[i].trimmingCharacters(in: .whitespaces)
                        if rowLine.contains("|") && !rowLine.isEmpty {
                            rows.append(parsePipeRow(rowLine))
                            i += 1
                        } else {
                            break
                        }
                    }
                    blocks.append(.tableBlock(headers: headers, rows: rows))
                    continue
                }
            }

            if let match = trimmed.range(of: #"^(\s*)[*\-+]\s+"#, options: .regularExpression) {
                let prefix = trimmed[match]
                let depth = prefix.filter({ $0 == " " || $0 == "\t" }).count / 2
                let itemText = String(trimmed[match.upperBound...])
                blocks.append(.unorderedListItem(depth: depth, text: itemText))
                i += 1
                continue
            }

            if let match = trimmed.range(of: #"^(\d+)\.\s+"#, options: .regularExpression) {
                let num = String(trimmed[match]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ".", with: "")
                let itemText = String(trimmed[match.upperBound...])
                blocks.append(.orderedListItem(number: num, text: itemText))
                i += 1
                continue
            }

            blocks.append(.paragraph(text: trimmed))
            i += 1
        }

        return blocks
    }

    private func parsePipeRow(_ line: String) -> [String] {
        return line
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Rendering

    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            renderHeading(level: level, text: text)
        case .codeBlock(_, let code):
            renderCodeBlock(code: code)
        case .unorderedListItem(let depth, let text):
            renderUnorderedListItem(depth: depth, text: text)
        case .orderedListItem(let number, let text):
            renderOrderedListItem(number: number, text: text)
        case .tableBlock(let headers, let rows):
            renderTable(headers: headers, rows: rows)
        case .paragraph(let text):
            renderInlineText(text)
                .font(.subheadline)
        case .horizontalRule:
            Divider().padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func renderHeading(level: Int, text: String) -> some View {
        let font: Font = {
            switch level {
            case 1: return .title2.bold()
            case 2: return .title3.bold()
            case 3: return .headline
            case 4: return .subheadline.bold()
            default: return .footnote.bold()
            }
        }()
        renderInlineText(text)
            .font(font)
            .padding(.top, level <= 2 ? 8 : 4)
    }

    @ViewBuilder
    private func renderCodeBlock(code: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(10)
        }
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func renderUnorderedListItem(depth: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\u{2022}")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            renderInlineText(text)
                .font(.subheadline)
        }
        .padding(.leading, CGFloat(depth * 16))
    }

    @ViewBuilder
    private func renderOrderedListItem(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(number).")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 18, alignment: .trailing)
            renderInlineText(text)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private func renderTable(headers: [String], rows: [[String]]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                        Text(header)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(minWidth: 80, alignment: .leading)
                    }
                }
                .background(Color.primary.opacity(0.06))

                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(stripInlineMarkdown(cell))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .frame(minWidth: 80, alignment: .leading)
                        }
                    }
                }
            }
        }
        .background(Color.primary.opacity(0.02), in: RoundedRectangle(cornerRadius: 6))
        .padding(.vertical, 2)
    }

    // MARK: - Inline Text

    private func renderInlineText(_ text: String) -> Text {
        var result = Text("")
        let scanner = InlineScanner(text)
        for segment in scanner.parse() {
            switch segment {
            case .plain(let str):
                result = result + Text(str)
            case .bold(let str):
                result = result + Text(str).bold()
            case .italic(let str):
                result = result + Text(str).italic()
            case .boldItalic(let str):
                result = result + Text(str).bold().italic()
            case .code(let str):
                result = result + Text(str).font(.system(.footnote, design: .monospaced)).foregroundColor(Color.accentColor)
            }
        }
        return result
    }

    private func stripInlineMarkdown(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "***", with: "")
        result = result.replacingOccurrences(of: "**", with: "")
        result = result.replacingOccurrences(of: "__", with: "")
        result = result.replacingOccurrences(of: "*", with: "")
        result = result.replacingOccurrences(of: "_", with: "")
        result = result.replacingOccurrences(of: "`", with: "")
        return result
    }
}

// MARK: - Inline Scanner

private struct InlineScanner {
    enum Segment {
        case plain(String)
        case bold(String)
        case italic(String)
        case boldItalic(String)
        case code(String)
    }

    private let text: String

    init(_ text: String) {
        self.text = text
    }

    func parse() -> [Segment] {
        var segments: [Segment] = []
        var remaining = text[text.startIndex...]

        while !remaining.isEmpty {
            if remaining.hasPrefix("`") {
                let after = remaining.dropFirst()
                if let end = after.firstIndex(of: "`") {
                    segments.append(.code(String(after[after.startIndex..<end])))
                    remaining = after[after.index(after: end)...]
                    continue
                }
            }

            if remaining.hasPrefix("***") || remaining.hasPrefix("___") {
                let delim = String(remaining.prefix(3))
                let after = remaining.dropFirst(3)
                if let range = after.range(of: delim) {
                    segments.append(.boldItalic(String(after[after.startIndex..<range.lowerBound])))
                    remaining = after[range.upperBound...]
                    continue
                }
            }

            if remaining.hasPrefix("**") || remaining.hasPrefix("__") {
                let delim = String(remaining.prefix(2))
                let after = remaining.dropFirst(2)
                if let range = after.range(of: delim) {
                    segments.append(.bold(String(after[after.startIndex..<range.lowerBound])))
                    remaining = after[range.upperBound...]
                    continue
                }
            }

            if remaining.hasPrefix("*") || remaining.hasPrefix("_") {
                let delim = String(remaining.prefix(1))
                let after = remaining.dropFirst(1)
                if let range = after.range(of: delim) {
                    segments.append(.italic(String(after[after.startIndex..<range.lowerBound])))
                    remaining = after[range.upperBound...]
                    continue
                }
            }

            var plainEnd = remaining.index(after: remaining.startIndex)
            while plainEnd < remaining.endIndex {
                let ch = remaining[plainEnd]
                if ch == "`" || ch == "*" || ch == "_" { break }
                plainEnd = remaining.index(after: plainEnd)
            }
            segments.append(.plain(String(remaining[remaining.startIndex..<plainEnd])))
            remaining = remaining[plainEnd...]
        }

        return segments
    }
}
