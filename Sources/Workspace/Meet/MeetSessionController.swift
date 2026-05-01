import Foundation
import Combine

#if canImport(Daily)
import Daily
typealias MeetingVideoTrack = VideoTrack
#else
final class MeetingVideoTrack {}
#endif

@MainActor
final class MeetingStateManager: NSObject, ObservableObject {
    static let shared = MeetingStateManager()

    @Published var phase: MeetSessionPhase = .idle
    @Published var participants: [MeetingParticipant] = []
    @Published var messages: [MeetingMessage] = []
    @Published var chatThreads: [MeetingChatThread] = [MeetingChatThread(id: "general", title: "General")]
    @Published var isMicrophoneMuted = false
    @Published var isCameraEnabled = true
    @Published var isScreenSharing = false
    @Published var localParticipantID: String?
    @Published var localParticipantDisplayName = ""
    @Published var activeScreenShareParticipantID: String?
    @Published var spotlightedParticipantID: String?
    @Published var pinnedParticipantID: String?

    // Intelligence and Analytics
    @Published var sentimentScore: Double = 0.5 // 0 to 1
    @Published var engagementLevel: Double = 0.0 // 0 to 1
    @Published var transcript: String = ""
    @Published var meetingSummary: String = ""

    @Published var meetingIdInput = ""
    @Published var currentSession: MeetingSession?
    @Published var settings = MeetingSettingsState()
    @Published var diagnostics = MeetingDiagnosticsState()
    @Published var lobbyState = MeetingLobbyState()
    @Published var captions: [MeetingCaptionLine] = []
    @Published var networkQuality: MeetingNetworkQuality = .good
    @Published var backgroundEffect: MeetingBackgroundEffect = .off
    @Published var reactions: [MeetingReactionEvent] = []
    @Published var cpuWarnings: [MeetingCPUWarning] = []
    @Published var isPiPEnabled = false
    @Published var isPiPActive = false
    @Published var isChatEnabled = true
    @Published var isScreenShareAllowed = true
    @Published var hostParticipantID: String?
    @Published var adminParticipantIDs: Set<String> = []
    @Published var isMeetingLocked = false
    @Published var activeAudioProcessingState = "Disabled"
    @Published var isNoiseCancellationEnabled = false
    @Published var isCaptionsEnabled = false

    @Published var participantVideoTracks: [String: MeetingVideoTrack] = [:]
    @Published var participantScreenShareTracks: [String: MeetingVideoTrack] = [:]

    private let aiService = AIService.shared

    override init() {
        super.init()
    }

    func toggleMute() { isMicrophoneMuted.toggle() }
    func toggleCamera() { isCameraEnabled.toggle() }
    func toggleScreenShare() { isScreenSharing.toggle() }

    func leaveMeeting() async {
        phase = .ended
    }

    func endMeetingForEveryone() async {
        phase = .ended
    }

    // MARK: - Real-Time Analytics

    func updateEngagement() {
        // Calculate based on participant activity, video state, etc.
        let activeParticipants = participants.filter { !$0.isMuted || $0.hasVideo }.count
        engagementLevel = Double(activeParticipants) / Double(max(participants.count, 1))
    }

    func processRealTimeSentiment(text: String) async {
        // AI analysis of chat or captions for sentiment
        do {
            let prompt = "Analyze the sentiment of this meeting dialogue (0 to 1 score): \(text)"
            let result = try await aiService.processText(prompt: prompt, systemPrompt: "Return only a number.")
            if let score = Double(result) {
                sentimentScore = score
            }
        } catch { }
    }

    func generatePostMeetingSummary() async throws -> String {
        let prompt = "Generate a summary and action items for this meeting transcript: \(transcript)"
        meetingSummary = try await aiService.processText(prompt: prompt, systemPrompt: "Return structured markdown.")
        return meetingSummary
    }

    // MARK: - Admin & Controls
    var isCurrentUserHost: Bool { true } // Simplified
    var canAccessAdminControls: Bool { true }

    func setNoiseCancellationEnabled(_ enabled: Bool) { isNoiseCancellationEnabled = enabled }
    func setPiPEnabled(_ enabled: Bool) { isPiPEnabled = enabled; isPiPActive = enabled }
    func setBackgroundEffect(_ effect: MeetingBackgroundEffect) { backgroundEffect = effect }
    func setCaptionsEnabled(_ enabled: Bool) { isCaptionsEnabled = enabled }
    func sendReaction(_ emoji: String) {
        reactions.append(MeetingReactionEvent(id: UUID().uuidString, participantID: localParticipantID ?? "", participantName: localParticipantDisplayName, emoji: emoji, createdAt: Date()))
    }
    func toggleRaiseHand() { /* Logic */ }
    func setHandRaised(participantID: String, raised: Bool) { /* Logic */ }
    func dismissCPUWarning(_ id: String) { cpuWarnings.removeAll { $0.id == id } }
    func sendMessage(_ text: String, threadId: String = "general") {
        messages.append(MeetingMessage(id: UUID().uuidString, threadId: threadId, senderName: localParticipantDisplayName, text: text, sentAt: Date(), isSystem: false, deliveryState: .delivered, reactions: [:]))
    }
    func addThread(named name: String) { chatThreads.append(MeetingChatThread(id: UUID().uuidString, title: name)) }
    func reactToMessage(messageID: String, emoji: String) { /* Logic */ }
}

typealias MeetSessionController = MeetingStateManager
