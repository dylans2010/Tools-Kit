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

    @Published var displayNameInput = ""
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published var scheduledMeetings: [ScheduledMeeting] = []
    @Published var isPiPActive = false
    @Published var isChatEnabled = true
    @Published var isScreenShareAllowed = true
    @Published var hostParticipantID: String?
    @Published var adminParticipantIDs: Set<String> = []
    @Published var isMeetingLocked = false
    @Published var breakoutRooms: [MeetingBreakoutRoom] = []
    @Published var activeAudioProcessingState = "Disabled"
    @Published var isNoiseCancellationEnabled = false
    @Published var isCaptionsEnabled = false
    @Published var debugSnapshot: DailyDebugSnapshot = .empty

    @Published var participantVideoTracks: [String: MeetingVideoTrack] = [:]
    @Published var participantScreenShareTracks: [String: MeetingVideoTrack] = [:]

    private let aiService = AIService.shared
    private let resolver = MeetingResolver.shared

    override init() {
        super.init()
    }

    func toggleMute() { isMicrophoneMuted.toggle() }

    var videoDeviceOptions: [String] {
        MeetPermissionService.availableVideoDevices()
    }

    var availableAudioDevices: [String] {
        MeetPermissionService.availableAudioDevices()
    }

    func toggleCamera() { isCameraEnabled.toggle() }
    func toggleScreenShare() { isScreenSharing.toggle() }

    var isMeetingIDFormatValid: Bool {
        let trimmed = meetingIdInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= 3
    }

    func validateMeetingID() -> Bool {
        return isMeetingIDFormatValid
    }

    func leaveMeeting() async {
        phase = .ended
    }

    func endMeetingForEveryone() async {
        phase = .ended
    }

    func runLobbyChecks() async {
        lobbyState.isLoadingParticipants = true
        let permissionService = MeetPermissionService()
        lobbyState.microphonePermission = await permissionService.checkMicrophonePermission()
        lobbyState.cameraPermission = await permissionService.checkCameraPermission()
        lobbyState.isLoadingParticipants = false
    }

    func startMeeting() async {
        guard let session = currentSession else { return }
        await resolver.beginSession(session)
        phase = .inMeeting
        PluginEventBus.shared.emit(type: .meetStarted, payload: ["id": session.id, "name": session.name])
    }

    func joinMeeting() async {
        guard isMeetingIDFormatValid else {
            errorMessage = "Invalid Meeting ID"
            return
        }
        isBusy = true
        errorMessage = nil
        do {
            let session = try await resolver.joinSession(with: meetingIdInput)
            currentSession = session
            localParticipantDisplayName = displayNameInput
            phase = .lobby
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    func joinScheduledMeeting(_ scheduled: ScheduledMeeting) async {
        guard let meetingId = scheduled.meetingId else {
            errorMessage = "Meeting ID not available yet"
            return
        }
        isBusy = true
        errorMessage = nil
        do {
            let session = try await resolver.joinSession(with: meetingId)
            currentSession = session
            localParticipantDisplayName = displayNameInput
            phase = .lobby
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    func createMeeting(scheduleForLater: Bool, scheduledAt: Date) async {
        isBusy = true
        errorMessage = nil
        do {
            if scheduleForLater {
                let newScheduled = ScheduledMeeting(
                    id: UUID().uuidString,
                    name: meetingIdInput,
                    meetingId: nil,
                    scheduledAt: scheduledAt,
                    activationState: .pending
                )
                scheduledMeetings.append(newScheduled)
                meetingIdInput = ""
            } else {
                let session = try await resolver.createSession(with: meetingIdInput)
                currentSession = session
                localParticipantDisplayName = displayNameInput
                phase = .lobby
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }


    func muteAllParticipants() async {
        participants = participants.map { participant in
            var updated = participant
            if updated.role != .host {
                updated.isMuted = true
            }
            return updated
        }
    }

    func setMeetingLocked(_ locked: Bool) async { isMeetingLocked = locked }
    func setChatEnabled(_ enabled: Bool) async { isChatEnabled = enabled }
    func setScreenShareAllowed(_ allowed: Bool) async { isScreenShareAllowed = allowed }
    func spotlightParticipant(_ participantID: String?) async { spotlightedParticipantID = participantID }
    func pinParticipant(_ participantID: String?) async { pinnedParticipantID = participantID }

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

    var meetingStateLabel: String {
        switch phase {
        case .idle: return "Idle"
        case .lobby: return "Lobby"
        case .inMeeting: return "Live"
        case .ended: return "Ended"
        case .failed: return "Error"
        }
    }

    func createBreakoutRoom(named name: String) async {
        let room = MeetingBreakoutRoom(id: UUID().uuidString, name: name, participantIds: [])
        breakoutRooms.append(room)
    }

    func assignParticipant(_ participantID: String, to roomID: String?) async {
        participants = participants.map { participant in
            var updated = participant
            if updated.id == participantID {
                updated.breakoutRoomID = roomID
            }
            return updated
        }

        breakoutRooms = breakoutRooms.map { room in
            var updated = room
            updated.participantIds.removeAll { $0 == participantID }
            if roomID == updated.id {
                updated.participantIds.append(participantID)
            }
            return updated
        }
    }

    func refreshDebugSnapshot() async {
        debugSnapshot = await resolver.fetchDebugSnapshot()
    }

    func assignRole(participantID: String, role: MeetingParticipantRole) async {
        participants = participants.map { participant in
            var updated = participant
            if updated.id == participantID {
                updated.role = role
            }
            return updated
        }

        guard let session = currentSession else { return }
        await resolver.applyAdminAction(.assignRole(participantId: participantID, role: role), in: session)
    }

    func setParticipantMuted(participantID: String, muted: Bool) async {
        participants = participants.map { participant in
            var updated = participant
            if updated.id == participantID {
                updated.isMuted = muted
            }
            return updated
        }

        guard let session = currentSession else { return }
        await resolver.applyAdminAction(.setParticipantMuted(participantId: participantID, muted: muted), in: session)
    }

    func setParticipantVideoEnabled(participantID: String, enabled: Bool) async {
        participants = participants.map { participant in
            var updated = participant
            if updated.id == participantID {
                updated.hasVideo = enabled
            }
            return updated
        }

        guard let session = currentSession else { return }
        await resolver.applyAdminAction(.setParticipantVideoEnabled(participantId: participantID, enabled: enabled), in: session)
    }

    func removeParticipant(participantID: String) async {
        participants.removeAll { $0.id == participantID }
        breakoutRooms = breakoutRooms.map { room in
            var updated = room
            updated.participantIds.removeAll { $0 == participantID }
            return updated
        }

        guard let session = currentSession else { return }
        await resolver.applyAdminAction(.removeParticipant(participantId: participantID), in: session)
    }
}

typealias MeetSessionController = MeetingStateManager
