import Foundation
import Daily

/// Represents a meeting session with its metadata.
public struct MeetingSession: Identifiable, Equatable, Codable {
    public var id: String { sessionId }

    public let meetingId: String
    public let roomName: String
    public let sessionId: String
    public let createdAt: Date
    public let debugTraceId: String
}

/// Represents a persisted meeting for the meeting browser.
public struct PersistedMeeting: Identifiable, Codable {
    public let id: UUID
    public let displayName: String
    public let encryptedID: String
    public var scheduledTime: Date?
    public let createdAt: Date

    public init(id: UUID = UUID(), displayName: String, encryptedID: String, scheduledTime: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.displayName = displayName
        self.encryptedID = encryptedID
        self.scheduledTime = scheduledTime
        self.createdAt = createdAt
    }
}

/// Enum representing the phase of a meeting session.
public enum MeetSessionPhase: String, Codable {
    case idle
    case lobby
    case inMeeting
    case ended
    case failed
}

/// Enum representing the state of permissions.
public enum MeetPermissionState: String, Codable {
    case unknown
    case granted
    case denied
}

/// Model for a meeting message.
public struct MeetingMessage: Identifiable, Equatable, Codable {
    public let id: String
    public let threadId: String
    public let senderName: String
    public let text: String
    public let sentAt: Date
    public let isSystem: Bool
}

/// Model for a chat thread.
public struct MeetingChatThread: Identifiable, Equatable, Codable {
    public let id: String
    public let title: String
}

/// Preferences for meeting layout.
public enum MeetingLayoutPreference: String, CaseIterable, Identifiable, Codable {
    case grid = "Grid"
    case speaker = "Speaker"
    case sidebar = "Sidebar"

    public var id: String { rawValue }
}

/// Settings for meeting quality.
public enum MeetingQualitySetting: String, CaseIterable, Identifiable, Codable {
    case auto = "Auto"
    case standard = "Standard"
    case high = "High"

    public var id: String { rawValue }
}

/// State for meeting settings.
public struct MeetingSettingsState: Codable {
    public var selectedAudioDevice = "Default Microphone"
    public var selectedVideoDevice = "Default Camera"
    public var layoutPreference: MeetingLayoutPreference = .grid
    public var qualitySetting: MeetingQualitySetting = .auto
}

/// State for meeting summary and AI recap.
public struct MeetingSummaryState: Codable {
    public var recap = "AI recap will appear after the meeting."
    public var actionItems: [String] = []
    public var transcriptPreview = "Transcript preview is not available yet."
}

/// State for the meeting lobby.
public struct MeetingLobbyState {
    public var isLoadingParticipants = true
    public var isCheckingDevices = true
    public var microphonePermission: MeetPermissionState = .unknown
    public var cameraPermission: MeetPermissionState = .unknown
}

/// Snapshot for debugging Daily sessions.
public struct DailyDebugMapping: Identifiable {
    public let id: String
    public let meetingId: String
    public let roomName: String
    public let sessionId: String
    public let createdAt: Date
    public let debugTraceId: String
}

/// Container for Daily debug mappings.
public struct DailyDebugSnapshot {
    public let mappings: [DailyDebugMapping]
    public let activeSessions: [MeetingSession]

    public static let empty = DailyDebugSnapshot(mappings: [], activeSessions: [])
}
