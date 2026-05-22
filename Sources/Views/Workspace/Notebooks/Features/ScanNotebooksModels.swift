import Foundation
import SwiftUI

// MARK: - Extraction Mode

enum ScanExtractionMode: String, CaseIterable, Identifiable, Codable {
    case fullText     = "Full Text"
    case summary      = "Summary"
    case keyPoints    = "Key Points"
    case actionItems  = "Action Items"
    case flashcards   = "Flashcards"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fullText:    return "doc.text"
        case .summary:     return "text.redaction"
        case .keyPoints:   return "list.bullet.rectangle.portrait"
        case .actionItems: return "checklist"
        case .flashcards:  return "rectangle.on.rectangle.angled"
        }
    }

    var systemPrompt: String {
        switch self {
        case .fullText:
            return ""
        case .summary:
            return "You are an expert summarizer. Given the raw OCR text from a scanned document, produce a concise summary preserving all key information. Return only the summary, no preamble."
        case .keyPoints:
            return "You extract key points. Given the raw OCR text, return a JSON array of strings, each a key point. Return ONLY valid JSON."
        case .actionItems:
            return "You extract action items. Given the raw OCR text, return a JSON array of objects with keys \"task\" (string) and \"done\" (bool, default false). Return ONLY valid JSON."
        case .flashcards:
            return "You create flashcards. Given the raw OCR text, return a JSON array of objects with keys \"question\" and \"answer\". Return ONLY valid JSON."
        }
    }

    var userPrompt: String {
        switch self {
        case .fullText:    return ""
        case .summary:     return "Summarize the following scanned text:"
        case .keyPoints:   return "Extract key points from the following scanned text as a JSON array of strings:"
        case .actionItems: return "Extract action items from the following scanned text as a JSON array of {\"task\": string, \"done\": bool}:"
        case .flashcards:  return "Create flashcards from the following scanned text as a JSON array of {\"question\": string, \"answer\": string}:"
        }
    }
}

// MARK: - Structured Extraction Result

enum ScanExtractionResult: Codable, Equatable {
    case fullText(String)
    case summary(String)
    case keyPoints([String])
    case actionItems([ScanActionItem])
    case flashcards([ScanFlashcard])

    var displayTitle: String {
        switch self {
        case .fullText:    return "Full Text"
        case .summary:     return "Summary"
        case .keyPoints:   return "Key Points"
        case .actionItems: return "Action Items"
        case .flashcards:  return "Flashcards"
        }
    }

    var plainText: String {
        switch self {
        case .fullText(let t):    return t
        case .summary(let t):     return t
        case .keyPoints(let pts): return pts.enumerated().map { "• \($0.element)" }.joined(separator: "\n")
        case .actionItems(let items):
            return items.map { ($0.done ? "☑" : "☐") + " \($0.task)" }.joined(separator: "\n")
        case .flashcards(let cards):
            return cards.map { "Q: \($0.question)\nA: \($0.answer)" }.joined(separator: "\n\n")
        }
    }
}

struct ScanActionItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var task: String
    var done: Bool

    enum CodingKeys: String, CodingKey {
        case task, done
    }

    init(task: String, done: Bool = false) {
        self.task = task
        self.done = done
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.task = try c.decode(String.self, forKey: .task)
        self.done = try c.decodeIfPresent(Bool.self, forKey: .done) ?? false
    }
}

struct ScanFlashcard: Codable, Identifiable, Equatable {
    var id = UUID()
    var question: String
    var answer: String

    enum CodingKeys: String, CodingKey {
        case question, answer
    }

    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.question = try c.decode(String.self, forKey: .question)
        self.answer = try c.decode(String.self, forKey: .answer)
    }
}

// MARK: - Detected Structured Data

struct ScanDetectedData: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: DetectedKind
    var rawText: String
    var confidence: Double

    enum DetectedKind: String, Codable, CaseIterable {
        case table
        case checklist
        case date
        case email
        case url
        case phoneNumber

        var icon: String {
            switch self {
            case .table:       return "tablecells"
            case .checklist:   return "checklist"
            case .date:        return "calendar"
            case .email:       return "envelope"
            case .url:         return "link"
            case .phoneNumber: return "phone"
            }
        }

        var label: String {
            switch self {
            case .table:       return "Table"
            case .checklist:   return "Checklist"
            case .date:        return "Date"
            case .email:       return "Email"
            case .url:         return "URL"
            case .phoneNumber: return "Phone"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case kind, rawText, confidence
    }

    init(kind: DetectedKind, rawText: String, confidence: Double = 1.0) {
        self.kind = kind
        self.rawText = rawText
        self.confidence = confidence
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try c.decode(DetectedKind.self, forKey: .kind)
        self.rawText = try c.decode(String.self, forKey: .rawText)
        self.confidence = try c.decodeIfPresent(Double.self, forKey: .confidence) ?? 1.0
    }
}

// MARK: - Unreadable Region

struct ScanUnreadableRegion: Identifiable, Equatable {
    let id = UUID()
    let boundingBox: CGRect
    let reason: String
}

// MARK: - Quality Feedback

struct ScanQualityFeedback: Equatable {
    var isBlurry: Bool = false
    var isLowLight: Bool = false
    var isSkewed: Bool = false
    var overallScore: Double = 1.0

    var issues: [String] {
        var result: [String] = []
        if isBlurry   { result.append("Image appears blurry") }
        if isLowLight { result.append("Low lighting detected") }
        if isSkewed   { result.append("Document may be skewed") }
        return result
    }

    var hasIssues: Bool { !issues.isEmpty }
}

// MARK: - Chat Message

struct ScanChatMessage: Codable, Identifiable, Equatable {
    var id = UUID()
    var role: Role
    var content: String
    var timestamp: Date

    enum Role: String, Codable {
        case user, assistant
    }

    enum CodingKeys: String, CodingKey {
        case role, content, timestamp
    }

    init(role: Role, content: String, timestamp: Date = Date()) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try c.decode(Role.self, forKey: .role)
        self.content = try c.decode(String.self, forKey: .content)
        self.timestamp = try c.decode(Date.self, forKey: .timestamp)
    }
}

// MARK: - Transform Format

enum ScanTransformFormat: String, CaseIterable, Identifiable {
    case tasks          = "Tasks"
    case note           = "Note"
    case presentation   = "Presentation"
    case report         = "Report"
    case spreadsheet    = "Spreadsheet"
    case calendarEvents = "Calendar Events"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tasks:          return "checklist"
        case .note:           return "note.text"
        case .presentation:   return "play.rectangle"
        case .report:         return "doc.richtext"
        case .spreadsheet:    return "tablecells"
        case .calendarEvents: return "calendar.badge.plus"
        }
    }

    var systemPrompt: String {
        switch self {
        case .tasks:
            return "Convert the scanned content into a structured task list. Return a JSON array of {\"task\": string, \"priority\": \"high\"|\"medium\"|\"low\"}. Return ONLY valid JSON."
        case .note:
            return "Reformat the scanned content into a clean, well-structured note with headings, bullet points, and paragraphs. Return clean markdown."
        case .presentation:
            return "Convert the scanned content into presentation slides. Return a JSON array of {\"title\": string, \"bullets\": [string]}. Return ONLY valid JSON."
        case .report:
            return "Transform the scanned content into a professional report with an executive summary, findings, and recommendations. Return clean markdown."
        case .spreadsheet:
            return "Extract any tabular or list data from the scanned content. Return a JSON object with \"headers\": [string] and \"rows\": [[string]]. Return ONLY valid JSON."
        case .calendarEvents:
            return "Extract any dates, deadlines, or scheduled items from the scanned content. Return a JSON array of {\"title\": string, \"date\": string, \"notes\": string}. Return ONLY valid JSON."
        }
    }
}

// MARK: - Scan Record (persistent context)

struct ScanRecord: Codable, Identifiable, Equatable {
    var id: UUID
    var rawText: String
    var extractionMode: ScanExtractionMode
    var result: ScanExtractionResult
    var detectedData: [ScanDetectedData]
    var chatMessages: [ScanChatMessage]
    var tags: [String]
    var timestamp: Date
    var linkedScanIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case id, rawText, extractionMode, result, detectedData, chatMessages, tags, timestamp, linkedScanIDs
    }

    init(
        rawText: String,
        extractionMode: ScanExtractionMode,
        result: ScanExtractionResult,
        detectedData: [ScanDetectedData] = [],
        chatMessages: [ScanChatMessage] = [],
        tags: [String] = [],
        linkedScanIDs: [UUID] = []
    ) {
        self.id = UUID()
        self.rawText = rawText
        self.extractionMode = extractionMode
        self.result = result
        self.detectedData = detectedData
        self.chatMessages = chatMessages
        self.tags = tags
        self.timestamp = Date()
        self.linkedScanIDs = linkedScanIDs
    }
}

// MARK: - Scan Context Store

@MainActor
final class ScanContextStore: ObservableObject {
    static let shared = ScanContextStore()

    @Published private(set) var records: [ScanRecord] = []

    private let storageURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("ScanNotebooks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("scan_records.json")
        loadRecords()
    }

    func loadRecords() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([ScanRecord].self, from: data) else { return }
        records = decoded.sorted { $0.timestamp > $1.timestamp }
    }

    func addRecord(_ record: ScanRecord) {
        records.insert(record, at: 0)
        persist()
    }

    func updateRecord(_ record: ScanRecord) {
        guard let idx = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[idx] = record
        persist()
    }

    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        persist()
    }

    func record(for id: UUID) -> ScanRecord? {
        records.first { $0.id == id }
    }

    func search(query: String) -> [ScanRecord] {
        let q = query.lowercased()
        return records.filter {
            $0.rawText.lowercased().contains(q) ||
            $0.result.plainText.lowercased().contains(q) ||
            $0.tags.contains(where: { $0.lowercased().contains(q) })
        }
    }

    func linkedRecords(for record: ScanRecord) -> [ScanRecord] {
        record.linkedScanIDs.compactMap { lid in records.first { $0.id == lid } }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
