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

struct SpeechAnalysis: Codable {
    var summary: String
    var keyPoints: [String]
    var actionItems: [String]
    var topics: [SpeechTopic]
    var fullTranscript: String

    init(summary: String = "", keyPoints: [String] = [], actionItems: [String] = [], topics: [SpeechTopic] = [], fullTranscript: String = "") {
        self.summary = summary
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.topics = topics
        self.fullTranscript = fullTranscript
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

    init(id: UUID = UUID(),
         title: String,
         date: Date = Date(),
         duration: TimeInterval = 0,
         audioFilename: String,
         transcriptSegments: [SpeechTranscriptSegment] = [],
         analysis: SpeechAnalysis? = nil,
         chatHistory: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.audioFilename = audioFilename
        self.transcriptSegments = transcriptSegments
        self.analysis = analysis
        self.chatHistory = chatHistory
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
