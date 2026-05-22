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

    var prompt: String {
        switch self {
        case .fullText:
            return "Return the full OCR text exactly as extracted, cleaned up for readability."
        case .summary:
            return "Summarize the following scanned text concisely while preserving all key information. Return a structured summary with a title and body."
        case .keyPoints:
            return "Extract the most important key points from this scanned text. Return as a JSON array of strings, each a key point."
        case .actionItems:
            return "Extract all action items, tasks, and to-dos from this scanned text. Return as a JSON array of objects with 'title' and optional 'dueDate' (ISO8601) fields."
        case .flashcards:
            return "Create study flashcards from this scanned text. Return as a JSON array of objects with 'question' and 'answer' fields."
        }
    }

    var systemPrompt: String {
        switch self {
        case .fullText:
            return "You clean up OCR text. Fix obvious OCR errors while preserving structure. Return only the cleaned text."
        case .summary:
            return "You are an expert summarizer. Return JSON with 'title' (string) and 'body' (string) fields."
        case .keyPoints:
            return "You extract key points. Return a JSON array of strings. No extra commentary."
        case .actionItems:
            return "You extract actionable tasks. Return a JSON array of objects with 'title' (string) and optional 'dueDate' (ISO8601 string) fields."
        case .flashcards:
            return "You create study flashcards. Return a JSON array of objects with 'question' and 'answer' fields."
        }
    }
}

// MARK: - Structured Extraction Results

struct ScanSummaryResult: Codable, Equatable {
    var title: String
    var body: String
}

struct ScanFlashcard: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var question: String
    var answer: String

    enum CodingKeys: String, CodingKey {
        case question, answer
    }

    init(question: String, answer: String) {
        self.id = UUID()
        self.question = question
        self.answer = answer
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.question = try c.decode(String.self, forKey: .question)
        self.answer = try c.decode(String.self, forKey: .answer)
    }
}

struct ScanActionItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var dueDate: String?
    var isCompleted: Bool = false

    enum CodingKeys: String, CodingKey {
        case title, dueDate
    }

    init(title: String, dueDate: String? = nil) {
        self.id = UUID()
        self.title = title
        self.dueDate = dueDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try c.decode(String.self, forKey: .title)
        self.dueDate = try c.decodeIfPresent(String.self, forKey: .dueDate)
    }
}

// MARK: - Structured Data Detection

enum DetectedStructure: String, Codable, Identifiable, Equatable {
    case table      = "Table"
    case checklist  = "Checklist"
    case date       = "Date"
    case equation   = "Equation"
    case list       = "List"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .table:     return "tablecells"
        case .checklist: return "checklist"
        case .date:      return "calendar"
        case .equation:  return "function"
        case .list:      return "list.bullet"
        }
    }
}

struct DetectedStructureItem: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var kind: DetectedStructure
    var rawText: String
    var lineRange: ClosedRange<Int>

    static func == (lhs: DetectedStructureItem, rhs: DetectedStructureItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Scan Result (persistent)

struct ScanResult: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var rawText: String
    var extractionMode: ScanExtractionMode
    var summaryResult: ScanSummaryResult?
    var keyPoints: [String]?
    var actionItems: [ScanActionItem]?
    var flashcards: [ScanFlashcard]?
    var detectedStructures: [DetectedStructureItem]
    var imageData: Data?
    var tags: [String]
    var createdAt: Date = Date()

    var displayTitle: String {
        if let summary = summaryResult {
            return summary.title
        }
        let preview = rawText.prefix(60)
        return preview.isEmpty ? "Scan \(createdAt.formatted(.dateTime.month().day().hour().minute()))" : String(preview) + "…"
    }

    static func == (lhs: ScanResult, rhs: ScanResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Chat System

struct ScanChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var role: MessageRole
    var content: String
    var createdAt: Date = Date()

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
}

struct ScanChatSession: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var scanID: UUID
    var messages: [ScanChatMessage] = []
    var createdAt: Date = Date()

    static func == (lhs: ScanChatSession, rhs: ScanChatSession) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Transform Pipeline

enum ScanTransformTarget: String, CaseIterable, Identifiable, Codable {
    case note          = "Note"
    case tasks         = "Tasks"
    case presentation  = "Presentation"
    case report        = "Report"
    case spreadsheet   = "Spreadsheet"
    case calendarEvent = "Calendar Event"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .note:          return "note.text"
        case .tasks:         return "checklist"
        case .presentation:  return "rectangle.on.rectangle.angled"
        case .report:        return "doc.richtext"
        case .spreadsheet:   return "tablecells"
        case .calendarEvent: return "calendar.badge.plus"
        }
    }

    var prompt: String {
        switch self {
        case .note:
            return "Convert the following scanned text into a well-structured note with a title and organized content using markdown."
        case .tasks:
            return "Convert the following scanned text into a list of actionable tasks. Return JSON array of objects with 'title', 'description', and 'priority' (Low/Medium/High/Critical) fields."
        case .presentation:
            return "Convert the following scanned text into presentation slides. Return JSON array of objects with 'title' and 'bulletPoints' (array of strings) fields."
        case .report:
            return "Convert the following scanned text into a professional report with title, executive summary, sections, and conclusion. Return as markdown."
        case .spreadsheet:
            return "Extract any tabular data from the following scanned text. Return JSON with 'headers' (array of strings) and 'rows' (array of arrays of strings)."
        case .calendarEvent:
            return "Extract event/date information from the following scanned text. Return JSON with 'title', 'description', 'date' (ISO8601), and 'location' fields."
        }
    }

    var systemPrompt: String {
        switch self {
        case .note:
            return "You convert raw text into clean, structured markdown notes."
        case .tasks:
            return "You extract tasks from text. Return valid JSON array."
        case .presentation:
            return "You create slide outlines. Return valid JSON array."
        case .report:
            return "You write professional reports in markdown format."
        case .spreadsheet:
            return "You extract tabular data. Return valid JSON with 'headers' and 'rows'."
        case .calendarEvent:
            return "You extract event info. Return valid JSON."
        }
    }
}

struct ScanTransformResult: Identifiable, Equatable {
    var id: UUID = UUID()
    var target: ScanTransformTarget
    var content: String
    var createdAt: Date = Date()
}

// MARK: - Image Quality

enum ScanQualityIssue: String, Identifiable {
    case blur        = "Image appears blurry"
    case lowLight    = "Low lighting detected"
    case skewed      = "Document appears skewed"
    case partial     = "Text may be partially cut off"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .blur:     return "camera.metering.unknown"
        case .lowLight: return "sun.min"
        case .skewed:   return "skew"
        case .partial:  return "crop"
        }
    }
}

// MARK: - Scan History Filter

enum ScanHistoryFilter: String, CaseIterable, Identifiable {
    case all       = "All"
    case today     = "Today"
    case thisWeek  = "This Week"
    case thisMonth = "This Month"

    var id: String { rawValue }
}

// MARK: - Scan Step (expanded)

enum ScanStep: Int, CaseIterable {
    case capture   = 1
    case review    = 2
    case aiTools   = 3
    case chat      = 4
    case transform = 5
    case history   = 6
}
