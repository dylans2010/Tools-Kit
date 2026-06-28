import Foundation
import CoreGraphics

@available(iOS 27.0, *)
struct SCKRecordingSession: Identifiable, Codable {
    let id: UUID
    var title: String
    let startTime: Date
    var endTime: Date?
    var videoURL: URL?
    var transcript: [SCKTranscriptSegment]
    var ocrResults: [SCKOCRResult]
    var bookmarks: [SCKBookmark]
    var summary: String?
    var actionItems: [String]?
    var tags: [String]
    var featureType: SCKFeatureType

    var duration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }

    static var empty: SCKRecordingSession {
        SCKRecordingSession(
            id: UUID(),
            title: "New Recording",
            startTime: Date(),
            transcript: [],
            ocrResults: [],
            bookmarks: [],
            tags: [],
            featureType: .general
        )
    }
}

@available(iOS 27.0, *)
enum SCKFeatureType: String, Codable, CaseIterable {
    case general = "General"
    case aiCapture = "AI Capture"
    case meeting = "Meeting"
    case presentation = "Presentation"
    case study = "Study"
    case tutorial = "Tutorial"
    case bugReport = "Bug Report"
}

@available(iOS 27.0, *)
struct SCKTranscriptSegment: Identifiable, Codable {
    let id: UUID
    let timestamp: TimeInterval
    let text: String
    let speaker: String?
}

@available(iOS 27.0, *)
struct SCKOCRResult: Identifiable, Codable {
    let id: UUID
    let timestamp: TimeInterval
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

@available(iOS 27.0, *)
struct SCKBookmark: Identifiable, Codable {
    let id: UUID
    let timestamp: TimeInterval
    let title: String
    let note: String?
}
