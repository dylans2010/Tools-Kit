import Foundation

enum MeetSessionPhase: String {
    case idle
    case lobby
    case inMeeting
    case ended
    case failed
}

enum MeetPermissionState: String {
    case unknown
    case granted
    case denied
}

struct MeetingParticipant: Identifiable, Equatable {
    let id: String
    let displayName: String
    let joinedAt: Date
    var isSpeaking: Bool
    var isMuted: Bool
    var hasVideo: Bool
}

struct MeetingMessage: Identifiable, Equatable {
    let id: String
    let threadId: String
    let senderName: String
    let text: String
    let sentAt: Date
    let isSystem: Bool
}

struct MeetingChatThread: Identifiable, Equatable {
    let id: String
    let title: String
}

enum MeetingLayoutPreference: String, CaseIterable, Identifiable {
    case grid = "Grid"
    case speaker = "Speaker"
    case sidebar = "Sidebar"

    var id: String { rawValue }
}

enum MeetingQualitySetting: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case standard = "Standard"
    case high = "High"

    var id: String { rawValue }
}

struct MeetingSettingsState {
    var selectedAudioDevice = "Default Microphone"
    var selectedVideoDevice = "Default Camera"
    var layoutPreference: MeetingLayoutPreference = .grid
    var qualitySetting: MeetingQualitySetting = .auto
}

struct MeetingSummaryState {
    var recap = "AI recap will appear after the meeting."
    var actionItems: [String] = []
    var transcriptPreview = "Transcript preview is not available yet."
}

struct MeetingLobbyState {
    var isLoadingParticipants = true
    var isCheckingDevices = true
    var microphonePermission: MeetPermissionState = .unknown
    var cameraPermission: MeetPermissionState = .unknown
}

struct DailyDebugMapping: Identifiable {
    let id: String
    let meetingId: String
    let roomName: String
    let sessionId: String
    let createdAt: Date
    let debugTraceId: String
}

struct DailyDebugSnapshot {
    let mappings: [DailyDebugMapping]
    let activeSessions: [MeetingSession]

    static let empty = DailyDebugSnapshot(mappings: [], activeSessions: [])
}
