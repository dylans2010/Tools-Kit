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

enum MeetingParticipantRole: String, CaseIterable, Identifiable, Codable {
    case host
    case admin
    case participant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .host: return "Host"
        case .admin: return "Admin"
        case .participant: return "Participant"
        }
    }
}

struct MeetingParticipant: Identifiable, Equatable {
    let id: String
    let displayName: String
    let joinedAt: Date
    var isSpeaking: Bool
    var isMuted: Bool
    var hasVideo: Bool
    var isScreenSharing: Bool
    var role: MeetingParticipantRole
    var breakoutRoomID: String?
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

struct ScheduledMeeting: Identifiable, Equatable {
    let id: String
    let name: String
    var meetingId: String?
    let scheduledAt: Date
    var activationState: ScheduledMeetingActivationState
}

enum ScheduledMeetingActivationState: String, Equatable, Codable {
    case pending
    case active
}

struct MeetingBreakoutRoom: Identifiable, Equatable, Codable {
    let id: String
    var name: String
    var participantIds: [String]
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
    var selectedAudioDevice = ""
    var selectedVideoDevice = ""
    var layoutPreference: MeetingLayoutPreference = .grid
    var qualitySetting: MeetingQualitySetting = .auto
    var outputVolume: Double = 0.75
}

struct MeetingSummaryState {
    var recap = ""
    var actionItems: [String] = []
    var transcriptPreview = ""
}

struct MeetingLobbyState {
    var isLoadingParticipants = true
    var isCheckingDevices = true
    var microphonePermission: MeetPermissionState = .unknown
    var cameraPermission: MeetPermissionState = .unknown
}

struct MeetingDiagnosticsState {
    var connectionState = "Unknown"
    var networkQuality = "Unknown"
    var latencyMs: Int = 0
    var packetLossPercent: Double = 0
}

enum MeetingAdminAction: Equatable {
    case muteAll
    case setParticipantMuted(participantId: String, muted: Bool)
    case setParticipantVideoEnabled(participantId: String, enabled: Bool)
    case removeParticipant(participantId: String)
    case assignRole(participantId: String, role: MeetingParticipantRole)
    case lockMeeting(Bool)
    case setChatEnabled(Bool)
    case spotlightParticipant(participantId: String?)
    case pinParticipant(participantId: String?)
    case setScreenShareEnabled(Bool)
    case endMeetingForAll
    case createBreakoutRoom(name: String)
    case assignParticipantToBreakout(participantId: String, roomId: String?)
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
