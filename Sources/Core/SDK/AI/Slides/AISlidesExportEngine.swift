import Foundation
import Combine

@MainActor
public final class AISlidesExportEngine: ObservableObject {
    public static let shared = AISlidesExportEngine()

    @Published public private(set) var isExporting = false
    @Published public private(set) var exportProgress: Double = 0
    @Published public private(set) var lastExportURL: URL?
    @Published public private(set) var exportHistory: [ExportRecord] = []

    private init() {}

    // MARK: - Export

    public func export(deck: SlideDeck, format: ExportFormat, options: ExportOptions = .defaults) async throws -> ExportResult {
        isExporting = true
        exportProgress = 0
        defer { isExporting = false }

        let startTime = Date()

        exportProgress = 0.1
        let content = try renderContent(deck: deck, format: format, options: options)

        exportProgress = 0.5
        let fileName = sanitizeFileName(deck.title) + format.fileExtension
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        exportProgress = 0.8
        try content.write(to: outputURL, atomically: true, encoding: .utf8)

        exportProgress = 1.0
        lastExportURL = outputURL

        let record = ExportRecord(
            deckID: deck.id,
            deckTitle: deck.title,
            format: format,
            slideCount: deck.slides.count,
            fileSize: fileSize(at: outputURL),
            duration: Date().timeIntervalSince(startTime)
        )
        exportHistory.append(record)

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "slides.export",
            name: "export.completed",
            data: ["format": format.rawValue, "slides": "\(deck.slides.count)"]
        ))

        return ExportResult(url: outputURL, format: format, fileSize: record.fileSize)
    }

    // MARK: - Render

    private func renderContent(deck: SlideDeck, format: ExportFormat, options: ExportOptions) throws -> String {
        switch format {
        case .html:
            return renderHTML(deck: deck, options: options)
        case .markdown:
            return renderMarkdown(deck: deck, options: options)
        case .plainText:
            return renderPlainText(deck: deck)
        case .json:
            return renderJSON(deck: deck)
        case .csv:
            return renderCSV(deck: deck)
        }
    }

    private func renderHTML(deck: SlideDeck, options: ExportOptions) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(deck.title)</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; padding: 0; }
                .slide { page-break-after: always; padding: 60px; min-height: 100vh; box-sizing: border-box; }
                .slide-title { font-size: 2.5em; margin-bottom: 0.5em; }
                .slide-body { font-size: 1.2em; line-height: 1.6; }
                .slide-notes { font-size: 0.9em; color: #666; border-top: 1px solid #ddd; padding-top: 1em; margin-top: 2em; }
                .slide-number { position: absolute; bottom: 20px; right: 30px; color: #999; }
            </style>
        </head>
        <body>
        """

        for (index, slide) in deck.slides.enumerated() {
            html += """
            <div class="slide">
                <div class="slide-title">\(slide.title)</div>
                <div class="slide-body">
            """
            for bullet in slide.bullets {
                html += "    <p>\(bullet)</p>\n"
            }
            html += "    </div>\n"
            if options.includeNotes, let notes = slide.speakerNotes, !notes.isEmpty {
                html += "    <div class=\"slide-notes\"><strong>Notes:</strong> \(notes)</div>\n"
            }
            if options.includeSlideNumbers {
                html += "    <div class=\"slide-number\">\(index + 1) / \(deck.slides.count)</div>\n"
            }
            html += "</div>\n"
        }

        html += "</body>\n</html>"
        return html
    }

    private func renderMarkdown(deck: SlideDeck, options: ExportOptions) -> String {
        var md = "# \(deck.title)\n\n"
        for (index, slide) in deck.slides.enumerated() {
            md += "---\n\n"
            md += "## \(slide.title)\n\n"
            for bullet in slide.bullets {
                md += "- \(bullet)\n"
            }
            if options.includeNotes, let notes = slide.speakerNotes, !notes.isEmpty {
                md += "\n> **Notes:** \(notes)\n"
            }
            if options.includeSlideNumbers {
                md += "\n*Slide \(index + 1) of \(deck.slides.count)*\n"
            }
            md += "\n"
        }
        return md
    }

    private func renderPlainText(deck: SlideDeck) -> String {
        var text = "\(deck.title)\n" + String(repeating: "=", count: deck.title.count) + "\n\n"
        for (index, slide) in deck.slides.enumerated() {
            text += "[\(index + 1)] \(slide.title)\n"
            for bullet in slide.bullets {
                text += "  - \(bullet)\n"
            }
            text += "\n"
        }
        return text
    }

    private func renderJSON(deck: SlideDeck) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(deck),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private func renderCSV(deck: SlideDeck) -> String {
        var csv = "Slide Number,Title,Bullet Points,Speaker Notes\n"
        for (index, slide) in deck.slides.enumerated() {
            let bullets = slide.bullets.joined(separator: "; ")
            let notes = slide.speakerNotes ?? ""
            csv += "\(index + 1),\"\(slide.title)\",\"\(bullets)\",\"\(notes)\"\n"
        }
        return csv
    }

    // MARK: - Helpers

    private func sanitizeFileName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        return name.unicodeScalars.filter { allowed.contains($0) }
            .map { String($0) }
            .joined()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
    }

    private func fileSize(at url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }
}

// MARK: - Models

public enum ExportFormat: String, Codable, CaseIterable, Sendable, Identifiable {
    case html, markdown, plainText, json, csv

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .html: return ".html"
        case .markdown: return ".md"
        case .plainText: return ".txt"
        case .json: return ".json"
        case .csv: return ".csv"
        }
    }

    public var displayName: String {
        switch self {
        case .html: return "HTML Presentation"
        case .markdown: return "Markdown"
        case .plainText: return "Plain Text"
        case .json: return "JSON Data"
        case .csv: return "CSV Spreadsheet"
        }
    }
}

public struct ExportOptions: Sendable {
    public var includeNotes: Bool
    public var includeSlideNumbers: Bool
    public var includeTheme: Bool

    public static let defaults = ExportOptions(includeNotes: true, includeSlideNumbers: true, includeTheme: true)

    public init(includeNotes: Bool = true, includeSlideNumbers: Bool = true, includeTheme: Bool = true) {
        self.includeNotes = includeNotes
        self.includeSlideNumbers = includeSlideNumbers
        self.includeTheme = includeTheme
    }
}

public struct ExportResult: Sendable {
    public let url: URL
    public let format: ExportFormat
    public let fileSize: Int64
}

public struct ExportRecord: Identifiable, Sendable {
    public let id = UUID()
    public let deckID: UUID
    public let deckTitle: String
    public let format: ExportFormat
    public let slideCount: Int
    public let fileSize: Int64
    public let duration: TimeInterval
    public let exportedAt: Date

    public init(deckID: UUID, deckTitle: String, format: ExportFormat, slideCount: Int, fileSize: Int64, duration: TimeInterval) {
        self.deckID = deckID
        self.deckTitle = deckTitle
        self.format = format
        self.slideCount = slideCount
        self.fileSize = fileSize
        self.duration = duration
        self.exportedAt = Date()
    }
}
