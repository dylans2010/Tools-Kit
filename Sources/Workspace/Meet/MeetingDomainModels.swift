import Foundation

enum MeetSessionPhase: String, Sendable {
    case idle
    case lobby
    case inMeeting
    case ended
    case failed
}

enum MeetPermissionState: String, Sendable {
    case unknown
    case granted
    case denied
}

enum MeetingParticipantRole: String, CaseIterable, Identifiable, Codable, Sendable {
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

struct MeetingParticipant: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let joinedAt: Date
    var isSpeaking: Bool
    var isMuted: Bool
    var hasVideo: Bool
    var isScreenSharing: Bool
    var role: MeetingParticipantRole
    var breakoutRoomID: String?
    var isHandRaised: Bool
    var networkQuality: MeetingNetworkQuality
}

enum MeetingMessageDeliveryState: String, Equatable, Sendable {
    case sent
    case delivered
}

struct MeetingMessage: Identifiable, Equatable, Sendable {
    let id: String
    let threadId: String
    let senderName: String
    let text: String
    let sentAt: Date
    let isSystem: Bool
    var deliveryState: MeetingMessageDeliveryState
    var reactions: [String: Int]
}

struct MeetingChatThread: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
}

struct ScheduledMeeting: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    var meetingId: String?
    let scheduledAt: Date
    var activationState: ScheduledMeetingActivationState
}

enum ScheduledMeetingActivationState: String, Equatable, Codable, Sendable {
    case pending
    case active
}

struct MeetingBreakoutRoom: Identifiable, Equatable, Codable, Sendable {
    let id: String
    var name: String
    var participantIds: [String]
}

enum MeetingLayoutPreference: String, CaseIterable, Identifiable, Sendable {
    case grid = "Grid"
    case speaker = "Speaker"
    case sidebar = "Sidebar"

    var id: String { rawValue }
}

enum MeetingQualitySetting: String, CaseIterable, Identifiable, Sendable {
    case auto = "Auto"
    case standard = "Standard"
    case high = "High"

    var id: String { rawValue }
}

struct MeetingSettingsState: Sendable {
    var selectedAudioDevice = ""
    var selectedVideoDevice = ""
    var layoutPreference: MeetingLayoutPreference = .grid
    var qualitySetting: MeetingQualitySetting = .auto
    var outputVolume: Double = 0.75
}

struct MeetingSummaryState: Sendable {
    var recap = ""
    var actionItems: [String] = []
    var transcriptPreview = ""
}

struct MeetingLobbyState: Sendable {
    var isLoadingParticipants = true
    var isCheckingDevices = true
    var microphonePermission: MeetPermissionState = .unknown
    var cameraPermission: MeetPermissionState = .unknown
}

struct MeetingDiagnosticsState: Sendable {
    var connectionState = "Unknown"
    var networkQuality = "Unknown"
    var latencyMs: Int = 0
    var packetLossPercent: Double = 0
}

enum MeetingNetworkQuality: Int, CaseIterable, Codable, Equatable, Sendable {
    case poor = 1
    case fair = 2
    case good = 3
    case excellent = 4

    var label: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
}

enum MeetingBackgroundEffect: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case off
    case blur
    case studio
    case office
    case beach

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .blur: return "Blur"
        case .studio: return "Studio"
        case .office: return "Office"
        case .beach: return "Beach"
        }
    }
}

struct MeetingCaptionLine: Identifiable, Equatable, Sendable {
    let id: String
    let speaker: String
    let text: String
    let timestamp: Date
}

struct MeetingReactionEvent: Identifiable, Equatable, Sendable {
    let id: String
    let participantID: String
    let participantName: String
    let emoji: String
    let createdAt: Date
}

struct MeetingCPUWarning: Identifiable, Equatable, Sendable {
    let id: String
    let message: String
    let suggestedAction: String
    let createdAt: Date
}

enum MeetingAdminAction: Equatable, Sendable {
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

struct DailyDebugMapping: Identifiable, Sendable {
    let id: String
    let meetingId: String
    let roomName: String
    let sessionId: String
    let createdAt: Date
    let debugTraceId: String
}

struct DailyDebugSnapshot: Sendable {
    let mappings: [DailyDebugMapping]
    let activeSessions: [MeetingSession]

    static let empty = DailyDebugSnapshot(mappings: [], activeSessions: [])
}
