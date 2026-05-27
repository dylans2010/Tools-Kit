import Foundation
import SwiftUI

enum SpeechAIAction: String, CaseIterable, Identifiable {
    case summarize = "Summarize"
    case keyPoints = "Key Points"
    case actionItems = "Action Items"
    case clarify = "Clarify"
    case expand = "Expand"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .summarize: return "text.alignleft"
        case .keyPoints: return "list.bullet.indent"
        case .actionItems: return "checkmark.circle"
        case .clarify: return "questionmark.circle"
        case .expand: return "arrow.up.right.and.arrow.down.left.rectangle"
        }
    }
}

struct SpeechTranscriptSegment: Codable, Identifiable, Hashable {
    let id: UUID
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String

    init(id: UUID = UUID(), startTime: TimeInterval, endTime: TimeInterval, text: String) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

struct SpeechTopic: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let startTime: TimeInterval
    let endTime: TimeInterval

    init(id: UUID = UUID(), title: String, startTime: TimeInterval, endTime: TimeInterval) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
    }
}

struct SpeechHighlight: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let summary: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Double
    let type: String // e.g., "Decision", "Insight", "Task"

    init(id: UUID = UUID(), title: String, summary: String, startTime: TimeInterval, endTime: TimeInterval, confidence: Double, type: String) {
        self.id = id
        self.title = title
        self.summary = summary
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
        self.type = type
    }
}

struct SpeechInsight: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String
    let type: String // "Topic", "Sentiment", "Intent"
    let importance: Int // 1-5
    let sourceSegmentIds: [UUID]

    init(id: UUID = UUID(), text: String, type: String, importance: Int, sourceSegmentIds: [UUID] = []) {
        self.id = id
        self.text = text
        self.type = type
        self.importance = importance
        self.sourceSegmentIds = sourceSegmentIds
    }
}

struct SmartSuggestion: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String
    let action: String
    let category: String // "Follow-up", "Transformation", "NextAction"

    init(id: UUID = UUID(), text: String, action: String, category: String) {
        self.id = id
        self.text = text
        self.action = action
        self.category = category
    }
}

struct SpeechVersion: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let date: Date
    let transcript: String
    let analysis: SpeechAnalysis?
    let parentId: UUID?

    init(id: UUID = UUID(), name: String, date: Date = Date(), transcript: String, analysis: SpeechAnalysis? = nil, parentId: UUID? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.transcript = transcript
        self.analysis = analysis
        self.parentId = parentId
    }
}

struct ContextMemoryPin: Codable, Identifiable, Hashable {
    let id: UUID
    let content: String
    let type: String // "Transcript", "Insight", "Chat"
    let date: Date

    init(id: UUID = UUID(), content: String, type: String, date: Date = Date()) {
        self.id = id
        self.content = content
        self.type = type
        self.date = date
    }
}

struct SpeechTag: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let colorHex: String

    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}

struct PromptExecutionRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let prompt: String
    let date: Date
    let response: String

    init(id: UUID = UUID(), prompt: String, date: Date = Date(), response: String) {
        self.id = id
        self.prompt = prompt
        self.date = date
        self.response = response
    }
}

struct SpeechAnalysis: Codable, Hashable, Equatable {
    var summary: String
    var keyPoints: [String]
    var actionItems: [String]
    var topics: [SpeechTopic]
    var fullTranscript: String
    var insights: [SpeechInsight]
    var highlights: [SpeechHighlight]
    var suggestions: [SmartSuggestion]
    var sentiment: String
    var intentClassification: String
    var priorityScore: Int

    init(summary: String = "",
         keyPoints: [String] = [],
         actionItems: [String] = [],
         topics: [SpeechTopic] = [],
         fullTranscript: String = "",
         insights: [SpeechInsight] = [],
         highlights: [SpeechHighlight] = [],
         suggestions: [SmartSuggestion] = [],
         sentiment: String = "Neutral",
         intentClassification: String = "Unknown",
         priorityScore: Int = 0) {
        self.summary = summary
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.topics = topics
        self.fullTranscript = fullTranscript
        self.insights = insights
        self.highlights = highlights
        self.suggestions = suggestions
        self.sentiment = sentiment
        self.intentClassification = intentClassification
        self.priorityScore = priorityScore
    }
}

struct SpeechRecording: Codable, Identifiable {
    let id: UUID
    var title: String
    let date: Date
    var duration: TimeInterval
    var audioFilename: String
    var transcriptSegments: [SpeechTranscriptSegment]
    var analysis: SpeechAnalysis?
    var chatHistory: [ChatMessage]
    var tags: [SpeechTag]
    var versions: [SpeechVersion]
    var pins: [ContextMemoryPin]
    var executionHistory: [PromptExecutionRecord]

    init(id: UUID = UUID(),
         title: String,
         date: Date = Date(),
         duration: TimeInterval = 0,
         audioFilename: String,
         transcriptSegments: [SpeechTranscriptSegment] = [],
         analysis: SpeechAnalysis? = nil,
         chatHistory: [ChatMessage] = [],
         tags: [SpeechTag] = [],
         versions: [SpeechVersion] = [],
         pins: [ContextMemoryPin] = [],
         executionHistory: [PromptExecutionRecord] = []) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.audioFilename = audioFilename
        self.transcriptSegments = transcriptSegments
        self.analysis = analysis
        self.chatHistory = chatHistory
        self.tags = tags
        self.versions = versions
        self.pins = pins
        self.executionHistory = executionHistory
    }
}

struct SpeechPresetPrompt: Identifiable, Codable {
    let id: UUID
    let title: String
    let prompt: String
    let category: String

    init(id: UUID = UUID(), title: String, prompt: String, category: String) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.category = category
    }
}
