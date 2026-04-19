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
    @Published var participantVideoTracks: [String: MeetingVideoTrack] = [:]
    @Published var localParticipantID: String?
    @Published var localParticipantDisplayName = ""
    @Published var chatThreads: [MeetingChatThread] = []
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
    private var participantRoles: [String: MeetingParticipantRole] = [:]
    private var activeSpeakerID: String?

    #if canImport(Daily)
    private var callClient: CallClient?
    #endif

    init(resolver: MeetingResolver = .shared) {
        self.resolver = resolver
        super.init()
    }

    var isMeetingIDFormatValid: Bool {
        isMeetingIDValid(meetingIdInput)
    }

    var availableAudioDevices: [String] {
        MeetPermissionService.availableAudioDevices()
    }

    var availableVideoDevices: [String] {
        MeetPermissionService.availableVideoDevices()
    }

    var isCurrentUserHost: Bool {
        guard let localParticipantID else { return false }
        return participants.first(where: { $0.id == localParticipantID })?.role == .host
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
        initializeDeviceSelectionIfNeeded(deviceType: "audio", availableDevices: availableAudioDevices, selectedDevice: &settings.selectedAudioDevice)
        initializeDeviceSelectionIfNeeded(deviceType: "video", availableDevices: availableVideoDevices, selectedDevice: &settings.selectedVideoDevice)
        lobbyState.isCheckingDevices = false
        lobbyState.isLoadingParticipants = false
    }

    func startMeeting() async {
        guard let currentSession else { return }
        guard let roomURL = await resolver.internalRoomURL(for: currentSession) else {
            errorMessage = "Meeting session is missing a Daily room URL."
            phase = .failed
            return
        }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            await resolver.beginSession(currentSession)
            try await joinDailyRoom(url: roomURL)
            phase = .inMeeting
            await refreshDebugSnapshot()
        } catch {
            phase = .failed
            errorMessage = error.localizedDescription
            DebugLogger.shared.log("Failed to start Daily session: \(error.localizedDescription)", level: .error, category: "Meet")
        }
    }

    func leaveMeeting() async {
        guard let currentSession else { return }
        await leaveDailyRoom()
        await resolver.endSession(currentSession)
        phase = .ended
        participants = []
        participantVideoTracks = [:]
        breakoutRooms = []
        participantRoles = [:]
        localParticipantID = nil
        localParticipantDisplayName = ""
        await refreshDebugSnapshot()
    }

    func toggleMute() {
        Task { await setMicrophoneEnabled(!isMicrophoneMuted) }
    }

    func toggleCamera() {
        Task { await setCameraEnabled(!isCameraEnabled) }
    }

    func toggleScreenShare() {
        isScreenSharing.toggle()
    }

    func sendMessage(_ text: String, threadId: String = "general") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard phase == .inMeeting else { return }
        errorMessage = "Chat is currently unavailable. This feature requires Daily session support."
        DebugLogger.shared.log("Blocked local-only chat send for thread \(threadId) to avoid non-Daily simulated state.", level: .warning, category: "Meet")
    }

    func addThread(named title: String) {
        errorMessage = "Creating new threads is currently unavailable. This feature requires Daily session support."
        DebugLogger.shared.log("Blocked local-only thread creation (\(title)) to avoid simulated state.", level: .warning, category: "Meet")
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
        await resolver.applyAdminAction(.muteAll, in: currentSession)
    }

    func setParticipantMuted(participantID: String, muted: Bool) async {
        guard let currentSession else { return }
        await resolver.applyAdminAction(.setParticipantMuted(participantId: participantID, muted: muted), in: currentSession)
    }

    func setParticipantVideoEnabled(participantID: String, enabled: Bool) async {
        guard let currentSession else { return }
        await resolver.applyAdminAction(.setParticipantVideoEnabled(participantId: participantID, enabled: enabled), in: currentSession)
    }

    func removeParticipant(participantID: String) async {
        guard let currentSession else { return }
        await resolver.applyAdminAction(.removeParticipant(participantId: participantID), in: currentSession)
    }

    func assignRole(participantID: String, role: MeetingParticipantRole) async {
        guard let currentSession else { return }
        await resolver.applyAdminAction(.assignRole(participantId: participantID, role: role), in: currentSession)
    }

    func createBreakoutRoom(named name: String) async {
        errorMessage = "Breakout room management is currently unavailable. This feature requires Daily session support."
        DebugLogger.shared.log("Blocked local-only breakout creation (\(name)) to avoid simulated state.", level: .warning, category: "Meet")
    }

    func assignParticipant(_ participantID: String, to roomID: String?) async {
        errorMessage = "Assigning participants to breakout rooms is currently unavailable. This feature requires Daily session support."
        DebugLogger.shared.log("Blocked local-only breakout assignment for participant \(participantID) room \(roomID ?? "main") to avoid simulated state.", level: .warning, category: "Meet")
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
        summary = MeetingSummaryState()
        diagnostics = MeetingDiagnosticsState()
        participants = []
        participantVideoTracks = [:]
        breakoutRooms = []
        messages = []
        chatThreads = []
        participantRoles = [:]
        localParticipantID = nil
        localParticipantDisplayName = ""
        await refreshDebugSnapshot()
    }

    private func isMeetingIDValid(_ value: String) -> Bool {
        let candidate = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
        return (4...24).contains(candidate.count) && candidate.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private func initializeDeviceSelectionIfNeeded(deviceType: String, availableDevices: [String], selectedDevice: inout String) {
        guard selectedDevice.isEmpty else { return }
        selectedDevice = availableDevices.first ?? ""
        if selectedDevice.isEmpty {
            DebugLogger.shared.log("No runtime \(deviceType) devices reported.", level: .warning, category: "Meet")
        }
    }

    private func setMicrophoneEnabled(_ enabled: Bool) async {
        #if canImport(Daily)
        await setInputEnabled([.microphone: enabled])
        #else
        await setInputEnabled(["microphone": enabled])
        #endif
    }

    private func setCameraEnabled(_ enabled: Bool) async {
        #if canImport(Daily)
        await setInputEnabled([.camera: enabled])
        #else
        await setInputEnabled(["camera": enabled])
        #endif
    }

    #if canImport(Daily)
    private func setInputEnabled(
        _ inputs: [OutboundMediaType: Bool]
    ) async {
        guard let callClient else { return }
        do {
            try await callClient.setInputsEnabled(inputs)
        } catch {
            errorMessage = "Failed to update media state: \(error.localizedDescription)"
        }
    }
    #else
    private func setInputEnabled(
        _ inputs: [String: Bool]
    ) async {
        let inputNames = inputs.keys.sorted().joined(separator: ", ")
        guard !inputNames.isEmpty else { return }
        errorMessage = "Daily SDK is unavailable, so \(inputNames) state cannot be updated."
        DebugLogger.shared.log("\(inputNames.capitalized) update blocked because Daily SDK is unavailable.", level: .warning, category: "Meet")
    }
    #endif

    private func leaveDailyRoom() async {
        #if canImport(Daily)
        guard let callClient else { return }
        defer {
            callClient.delegate = nil
            self.callClient = nil
        }
        do {
            try await callClient.stopLocalAudioLevelObserver()
            try await callClient.stopRemoteParticipantsAudioLevelObserver()
            try await callClient.leave()
        } catch {
            DebugLogger.shared.log("Daily leave failed: \(error.localizedDescription)", level: .warning, category: "Meet")
        }
        #endif
    }

    private func joinDailyRoom(url: URL) async throws {
        #if canImport(Daily)
        let callClient = try await ensureCallClient()
        let settings = ClientSettingsUpdate(
            inputs: .set(
                camera: .set(isEnabled: .set(isCameraEnabled)),
                microphone: .set(isEnabled: .set(!isMicrophoneMuted))
            )
        )
        try await callClient.join(url: url, token: nil, settings: settings)
        refreshParticipantsFromDaily()
        #else
        throw NSError(domain: "Meet", code: -1, userInfo: [NSLocalizedDescriptionKey: "Daily SDK is unavailable in this build."])
        #endif
    }

    #if canImport(Daily)
    private func ensureCallClient() async throws -> CallClient {
        if let callClient { return callClient }
        let callClient = CallClient()
        callClient.delegate = self
        self.callClient = callClient
        return callClient
    }

    private func refreshParticipantsFromDaily() {
        guard let callClient else { return }

        let allParticipants = callClient.participants.all.values
        let participantsWithNames = allParticipants.map { (participant: $0, displayName: participantDisplayName($0)) }
        let sortedParticipantsWithNames = participantsWithNames.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        let sortedParticipants = sortedParticipantsWithNames.map(\.participant)

        participantVideoTracks = Dictionary(uniqueKeysWithValues: sortedParticipants.compactMap { participant in
            guard let track = participant.media?.camera.track else { return nil }
            return (participantIDString(participant), track)
        })

        let currentLocalParticipant = sortedParticipants.first(where: { $0.info.isLocal })
        let currentLocalParticipantID = currentLocalParticipant.map { participantIDString($0) }
        localParticipantID = currentLocalParticipantID
        localParticipantDisplayName = currentLocalParticipant.map(participantDisplayName) ?? ""

        participants = sortedParticipants.map { participant in
            let participantID = participantIDString(participant)
            let isLocal = participant.info.isLocal
            let role = participantRoles[participantID] ?? (isLocal ? .host : .participant)
            let existingParticipant = participants.first(where: { $0.id == participantID })
            return MeetingParticipant(
                id: participantID,
                displayName: participantDisplayName(participant),
                joinedAt: existingParticipant?.joinedAt ?? Date(),
                isSpeaking: participantID == activeSpeakerID,
                isMuted: participant.media?.microphone.state != .playable,
                hasVideo: participant.media?.camera.state == .playable,
                role: role,
                breakoutRoomID: existingParticipant?.breakoutRoomID
            )
        }
    }

    private nonisolated func participantDisplayName(_ participant: Participant) -> String {
        let trimmed = participant.info.username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }
        return participantIDString(participant)
    }

    private nonisolated func participantIDString(_ participant: Participant) -> String {
        "\(participant.id)"
    }

    private func appendSystemMessage(_ text: String, threadId: String = "system", threadTitle: String = "System Messages") {
        let threadExists = chatThreads.contains { $0.id == threadId }
        if !threadExists {
            chatThreads.append(MeetingChatThread(id: threadId, title: threadTitle))
        }
        messages.append(
            MeetingMessage(
                id: UUID().uuidString,
                threadId: threadId,
                senderName: "System",
                text: text,
                sentAt: Date(),
                isSystem: true
            )
        )
    }
    #endif
}

#if canImport(Daily)
extension MeetingStateManager: CallClientDelegate {
    nonisolated func callClient(_ callClient: CallClient, callStateUpdated state: CallState) {
        Task { @MainActor in
            let stateDescription = String(describing: state)
            diagnostics.connectionState = stateDescription
            let normalized = stateDescription.lowercased()
            if normalized == "reconnecting" {
                appendSystemMessage("Reconnecting to meeting...")
            } else if normalized == "disconnected" || normalized == "left" {
                appendSystemMessage("Disconnected from meeting.")
            } else if normalized == "joined" || normalized == "connected" {
                appendSystemMessage("Connected to meeting.")
            } else if normalized == "failed" || normalized == "error" {
                appendSystemMessage("Connection failed.")
            }
            if state == .joined {
                phase = .inMeeting
            }
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, participantJoined participant: Participant) {
        Task { @MainActor in
            appendSystemMessage("\(participantDisplayName(participant)) joined.")
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, participantLeft participant: Participant, withReason reason: ParticipantLeftReason) {
        Task { @MainActor in
            let participantID = participantIDString(participant)
            participantVideoTracks.removeValue(forKey: participantID)
            if activeSpeakerID == participantID {
                activeSpeakerID = nil
            }
            appendSystemMessage("\(participantDisplayName(participant)) left.")
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, participantUpdated participant: Participant) {
        Task { @MainActor in
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, activeSpeakerChanged activeSpeaker: Participant?) {
        Task { @MainActor in
            activeSpeakerID = activeSpeaker.map { participantIDString($0) }
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, inputsUpdated inputs: InputSettings) {
        Task { @MainActor in
            isCameraEnabled = inputs.camera.isEnabled
            isMicrophoneMuted = !inputs.microphone.isEnabled
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, error: CallClientError) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}
#endif

typealias MeetSessionController = MeetingStateManager
