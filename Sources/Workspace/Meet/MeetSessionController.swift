import Foundation
import Combine

@MainActor
final class MeetingStateManager: ObservableObject {
    static let shared = MeetingStateManager()
    private let localParticipantID = "local"

    @Published var meetingIdInput = ""
    @Published var meetingNameInput = ""
    @Published var currentSession: MeetingSession?
    @Published var phase: MeetSessionPhase = .idle
    @Published var isBusy = false
    @Published var errorMessage: String?

    @Published var isMicrophoneMuted = false
    @Published var isCameraEnabled = true
    @Published var isScreenSharing = false

    @Published var participants: [MeetingParticipant] = []
    @Published var chatThreads: [MeetingChatThread] = [MeetingChatThread(id: "general", title: "General")]
    @Published var messages: [MeetingMessage] = []
    @Published var scheduledMeetings: [ScheduledMeeting] = []
    @Published var breakoutRooms: [MeetingBreakoutRoom] = []

    @Published var lobbyState = MeetingLobbyState()
    @Published var settings = MeetingSettingsState()
    @Published var diagnostics = MeetingDiagnosticsState()
    @Published var summary = MeetingSummaryState()
    @Published private(set) var debugSnapshot: DailyDebugSnapshot = .empty

    private let resolver: MeetingResolver
    private let permissionService = MeetPermissionService()

    init(resolver: MeetingResolver = .shared) {
        self.resolver = resolver
        self.scheduledMeetings = [
            ScheduledMeeting(id: UUID().uuidString, name: "Daily Standup", meetingId: "TEAM-STANDUP", scheduledAt: Date().addingTimeInterval(900)),
            ScheduledMeeting(id: UUID().uuidString, name: "Design Review", meetingId: "DESIGN-REVIEW", scheduledAt: Date().addingTimeInterval(3600))
        ]
    }

    var isMeetingIDFormatValid: Bool {
        isMeetingIDValid(meetingIdInput)
    }

    var availableAudioDevices: [String] {
        ["Default Microphone", "Built-in Microphone", "Bluetooth Headset"]
    }

    var availableVideoDevices: [String] {
        ["Default Camera", "Front Camera", "Back Camera"]
    }

    var isCurrentUserHost: Bool {
        participants.first(where: { $0.id == localParticipantID })?.role == .host
    }

    func validateMeetingID(_ value: String? = nil) -> Bool {
        let isValid = isMeetingIDValid(value ?? meetingIdInput)
        if !isValid {
            errorMessage = "Meeting ID must be 4-24 letters, numbers, or dashes."
        } else if errorMessage == "Meeting ID must be 4-24 letters, numbers, or dashes." {
            errorMessage = nil
        }
        return isValid
    }

    func generateMeetingID() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            meetingIdInput = try await resolver.generateMeetingID()
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.shared.log("Meeting ID generation failed: \(error.localizedDescription)", level: .error, category: "Meet")
        }
    }

    func createMeeting() async {
        let trimmedName = meetingNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Meeting name is required."
            return
        }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let session = try await resolver.createSession(with: nil)
            await transitionToLobby(session)
            meetingIdInput = session.meetingId
            scheduledMeetings.insert(
                ScheduledMeeting(
                    id: UUID().uuidString,
                    name: trimmedName,
                    meetingId: session.meetingId,
                    scheduledAt: Date()
                ),
                at: 0
            )
            DebugLogger.shared.log("Meeting created with backend-generated ID \(session.meetingId).", category: "Meet")
        } catch {
            phase = .failed
            errorMessage = error.localizedDescription
            DebugLogger.shared.log("Meeting creation failed: \(error.localizedDescription)", level: .error, category: "Meet")
        }
    }

    func joinMeeting() async {
        guard validateMeetingID() else { return }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let session = try await resolver.joinSession(with: meetingIdInput)
            await transitionToLobby(session)
        } catch {
            phase = .failed
            errorMessage = error.localizedDescription
            DebugLogger.shared.log("Join failed: \(error.localizedDescription)", level: .error, category: "Meet")
        }
    }

    func joinScheduledMeeting(_ scheduled: ScheduledMeeting) async {
        meetingIdInput = scheduled.meetingId
        await joinMeeting()
    }

    func runLobbyChecks() async {
        lobbyState.isLoadingParticipants = true
        lobbyState.isCheckingDevices = true

        async let mic = permissionService.checkMicrophonePermission()
        async let cam = permissionService.checkCameraPermission()

        lobbyState.microphonePermission = await mic
        lobbyState.cameraPermission = await cam
        lobbyState.isCheckingDevices = false
        lobbyState.isLoadingParticipants = false
    }

    func startMeeting() async {
        guard let currentSession else { return }
        await resolver.beginSession(currentSession)
        phase = .inMeeting
        ensureLocalParticipant()
        addSystemMessage("Connected to Daily media session.")
        await refreshDebugSnapshot()
    }

    func leaveMeeting() async {
        guard let currentSession else { return }
        await resolver.endSession(currentSession)
        phase = .ended
        addSystemMessage("Meeting ended.")
        participants = []
        breakoutRooms = []
        await refreshDebugSnapshot()
    }

    func toggleMute() {
        isMicrophoneMuted.toggle()
        if let index = participants.firstIndex(where: { $0.id == localParticipantID }) {
            participants[index].isMuted = isMicrophoneMuted
        }
    }

    func toggleCamera() {
        isCameraEnabled.toggle()
        if let index = participants.firstIndex(where: { $0.id == localParticipantID }) {
            participants[index].hasVideo = isCameraEnabled
        }
    }

    func toggleScreenShare() {
        isScreenSharing.toggle()
    }

    func sendMessage(_ text: String, threadId: String = "general") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(
            MeetingMessage(
                id: UUID().uuidString,
                threadId: threadId,
                senderName: "You",
                text: trimmed,
                sentAt: Date(),
                isSystem: false
            )
        )
    }

    func addThread(named title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatThreads.append(MeetingChatThread(id: UUID().uuidString, title: trimmed))
    }

    func setAudioDevice(_ device: String) {
        settings.selectedAudioDevice = device
    }

    func setVideoDevice(_ device: String) {
        settings.selectedVideoDevice = device
    }

    func setVideoQuality(_ quality: MeetingQualitySetting) {
        settings.qualitySetting = quality
    }

    func updateDeveloperAPIKey(_ value: String) async {
        await resolver.updateDeveloperAPIKey(value)
        await refreshDebugSnapshot()
    }

    func refreshDebugSnapshot() async {
        debugSnapshot = await resolver.fetchDebugSnapshot()
    }

    func muteAllParticipants() async {
        guard let currentSession else { return }
        for index in participants.indices where participants[index].id != localParticipantID {
            participants[index].isMuted = true
        }
        await resolver.applyAdminAction(.muteAll, in: currentSession)
    }

    func setParticipantMuted(participantID: String, muted: Bool) async {
        guard let currentSession else { return }
        guard let index = participants.firstIndex(where: { $0.id == participantID }) else { return }
        participants[index].isMuted = muted
        await resolver.applyAdminAction(.setParticipantMuted(participantId: participantID, muted: muted), in: currentSession)
    }

    func setParticipantVideoEnabled(participantID: String, enabled: Bool) async {
        guard let currentSession else { return }
        guard let index = participants.firstIndex(where: { $0.id == participantID }) else { return }
        participants[index].hasVideo = enabled
        await resolver.applyAdminAction(.setParticipantVideoEnabled(participantId: participantID, enabled: enabled), in: currentSession)
    }

    func removeParticipant(participantID: String) async {
        guard let currentSession else { return }
        participants.removeAll { $0.id == participantID }
        for index in breakoutRooms.indices {
            breakoutRooms[index].participantIds.removeAll { $0 == participantID }
        }
        await resolver.applyAdminAction(.removeParticipant(participantId: participantID), in: currentSession)
        await syncBreakoutRooms()
    }

    func assignRole(participantID: String, role: MeetingParticipantRole) async {
        guard let currentSession else { return }
        guard let index = participants.firstIndex(where: { $0.id == participantID }) else { return }
        participants[index].role = role
        await resolver.applyAdminAction(.assignRole(participantId: participantID, role: role), in: currentSession)
    }

    func createBreakoutRoom(named name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        breakoutRooms.append(MeetingBreakoutRoom(id: UUID().uuidString, name: trimmed, participantIds: []))
        await syncBreakoutRooms()
    }

    func assignParticipant(_ participantID: String, to roomID: String?) async {
        for index in breakoutRooms.indices {
            breakoutRooms[index].participantIds.removeAll { $0 == participantID }
        }

        if let roomID, let roomIndex = breakoutRooms.firstIndex(where: { $0.id == roomID }) {
            breakoutRooms[roomIndex].participantIds.append(participantID)
        }

        if let participantIndex = participants.firstIndex(where: { $0.id == participantID }) {
            participants[participantIndex].breakoutRoomID = roomID
        }

        await syncBreakoutRooms()
    }

    var meetingStateLabel: String {
        switch phase {
        case .idle: return "Idle"
        case .lobby: return "Lobby"
        case .inMeeting: return "In Meeting"
        case .ended: return "Ended"
        case .failed: return "Failed"
        }
    }

    func webViewDidStartLoadingPage() {}
    func webViewDidFinishLoadingPage() {}
    func webViewDidLeaveUnexpectedly() {}
    func webViewDidFail(_ message: String) { errorMessage = message }
    func webViewURL() -> URL? { nil }

    private func syncBreakoutRooms() async {
        guard let currentSession else { return }
        await resolver.updateBreakoutRooms(breakoutRooms, in: currentSession)
    }

    private func transitionToLobby(_ session: MeetingSession) async {
        currentSession = session
        meetingIdInput = session.meetingId
        phase = .lobby
        summary = MeetingSummaryState(
            recap: "AI recap will be generated after this meeting session.",
            actionItems: ["Capture blockers", "Summarize next steps"],
            transcriptPreview: "Transcript preview entry point is ready for integration."
        )
        diagnostics = MeetingDiagnosticsState(
            connectionState: "Connecting",
            networkQuality: "Good",
            latencyMs: 48,
            packetLossPercent: 0.5
        )
        participants = []
        breakoutRooms = []
        messages = []
        await refreshDebugSnapshot()
        addSystemMessage("Session prepared for meeting ID \(session.meetingId).")
    }

    private func addSystemMessage(_ text: String) {
        messages.append(
            MeetingMessage(
                id: UUID().uuidString,
                threadId: "general",
                senderName: "System",
                text: text,
                sentAt: Date(),
                isSystem: true
            )
        )
    }

    private func isMeetingIDValid(_ value: String) -> Bool {
        let candidate = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
        return (4...24).contains(candidate.count) && candidate.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private func ensureLocalParticipant() {
        if let index = participants.firstIndex(where: { $0.id == localParticipantID }) {
            participants[index].isMuted = isMicrophoneMuted
            participants[index].hasVideo = isCameraEnabled
            participants[index].role = .host
            return
        }
        participants.insert(
            MeetingParticipant(
                id: localParticipantID,
                displayName: "You",
                joinedAt: Date(),
                isSpeaking: false,
                isMuted: isMicrophoneMuted,
                hasVideo: isCameraEnabled,
                role: .host,
                breakoutRoomID: nil
            ),
            at: 0
        )

        participants.append(
            MeetingParticipant(
                id: "guest-1",
                displayName: "Alex",
                joinedAt: Date(),
                isSpeaking: true,
                isMuted: false,
                hasVideo: true,
                role: .participant,
                breakoutRoomID: nil
            )
        )
    }
}

typealias MeetSessionController = MeetingStateManager
