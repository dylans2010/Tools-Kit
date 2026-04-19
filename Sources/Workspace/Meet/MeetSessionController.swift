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
    private static let unauthorizedJoinErrorMarkers: Set<String> = [
        "unauthorized",
        "not authorized",
        "roomlookup"
    ]
    private static let guestDisplayName = "Guest"
    private static let dailyErrorWarningMessage = "Daily reported an error."
    private static let dailyErrorWarningAction = "Try turning off camera or reconnecting."
    private static let poorConnectionWarningMessage = "Connection quality is poor."
    static let shared = MeetingStateManager()
    private static let sensitiveQueryParameterNames: Set<String> = [
        "t", "token", "access_token", "refresh_token", "session", "session_token",
        "auth", "authorization", "password", "secret", "client_secret",
        "api_key", "apikey", "key", "bearer"
    ]
    private static let sensitiveUserInfoKeyFragments: Set<String> = [
        "token", "access_token", "refresh_token", "session_token",
        "authorization", "password", "secret", "client_secret",
        "api_key", "apikey", "credential", "cookie", "bearer"
    ]
    private static let sensitiveURLValuePattern: String = {
        let escaped = sensitiveQueryParameterNames.map(NSRegularExpression.escapedPattern(for:))
        return "(?i)([?&](?:\(escaped.joined(separator: "|")))=)[^&\\s]+"
    }()

    @Published var meetingIdInput = ""
    @Published var meetingNameInput = ""
    @Published var currentSession: MeetingSession?
    @Published var phase: MeetSessionPhase = .idle
    @Published var isBusy = false
    @Published private(set) var isJoining = false
    @Published var errorMessage: String?

    @Published var isMicrophoneMuted = false
    @Published var isCameraEnabled = true
    @Published var isScreenSharing = false
    @Published var displayNameInput = ""

    @Published var participants: [MeetingParticipant] = []
    @Published var participantVideoTracks: [String: MeetingVideoTrack] = [:]
    @Published var participantScreenShareTracks: [String: MeetingVideoTrack] = [:]
    @Published var localParticipantID: String?
    @Published var localParticipantDisplayName = ""
    @Published var chatThreads: [MeetingChatThread] = []
    @Published var messages: [MeetingMessage] = []
    @Published var scheduledMeetings: [ScheduledMeeting] = []
    @Published var breakoutRooms: [MeetingBreakoutRoom] = []
    @Published var hostParticipantID: String?
    @Published var adminParticipantIDs: Set<String> = []
    @Published var isMeetingLocked = false
    @Published var isChatEnabled = true
    @Published var isScreenShareAllowed = true
    @Published var spotlightedParticipantID: String?
    @Published var pinnedParticipantID: String?
    @Published var activeScreenShareParticipantID: String?

    @Published var lobbyState = MeetingLobbyState()
    @Published var settings = MeetingSettingsState()
    @Published var diagnostics = MeetingDiagnosticsState()
    @Published var summary = MeetingSummaryState()
    @Published var isNoiseCancellationEnabled = false
    @Published var activeAudioProcessingState = "Disabled"
    @Published var isCaptionsEnabled = false
    @Published var captions: [MeetingCaptionLine] = []
    @Published var networkQuality: MeetingNetworkQuality = .good
    @Published var backgroundEffect: MeetingBackgroundEffect = .off
    @Published var reactions: [MeetingReactionEvent] = []
    @Published var raisedHandParticipantIDs: Set<String> = []
    @Published var cpuWarnings: [MeetingCPUWarning] = []
    @Published var isPiPEnabled = false
    @Published var isPiPActive = false
    @Published private(set) var debugSnapshot: DailyDebugSnapshot = .empty

    private let resolver: MeetingResolver
    private let permissionService = MeetPermissionService()
    private var participantRoles: [String: MeetingParticipantRole] = [:]
    private var activeSpeakerID: String?
    private var activeStartedSession: MeetingSession?
    private var pendingCreatorHostAssignment = false
    private var lastBroadcastNetworkSignature = ""

    #if canImport(Daily)
    private var callClient: CallClient?
    #endif
    private let callKitManager = CallKitManager.shared
    private let piPController = PiPController()

    init(resolver: MeetingResolver = .shared) {
        self.resolver = resolver
        super.init()
        callKitManager.onAnswer = { [weak self] in
            guard let self else { return }
            Task { await self.startMeeting() }
        }
        callKitManager.onEnd = { [weak self] in
            guard let self else { return }
            Task { await self.leaveMeeting() }
        }
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
        return hostParticipantID == localParticipantID
    }

    var isCurrentUserAdmin: Bool {
        guard let localParticipantID else { return false }
        return isCurrentUserHost || adminParticipantIDs.contains(localParticipantID)
    }

    var canAccessAdminControls: Bool {
        isCurrentUserAdmin
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
        await createMeeting(scheduleForLater: false, scheduledAt: Date())
    }

    func createMeeting(scheduleForLater: Bool, scheduledAt: Date) async {
        let trimmedName = meetingNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Meeting name is required."
            return
        }

        if scheduleForLater {
            scheduledMeetings.insert(
                ScheduledMeeting(
                    id: UUID().uuidString,
                    name: trimmedName,
                    meetingId: nil,
                    scheduledAt: scheduledAt,
                    activationState: .pending
                ),
                at: 0
            )
            errorMessage = nil
            phase = .idle
            DebugLogger.shared.log("Scheduled meeting saved for \(scheduledAt.formatted(date: .abbreviated, time: .shortened)) with deferred activation.", category: "Meet")
            return
        }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let session = try await resolver.createSession(with: nil)
            pendingCreatorHostAssignment = true
            await transitionToLobby(session)
            meetingIdInput = session.meetingId
            scheduledMeetings.insert(
                ScheduledMeeting(
                    id: UUID().uuidString,
                    name: trimmedName,
                    meetingId: session.meetingId,
                    scheduledAt: Date(),
                    activationState: .active
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
            pendingCreatorHostAssignment = false
            await transitionToLobby(session)
        } catch {
            phase = .failed
            errorMessage = userFacingJoinErrorMessage(for: error)
            DebugLogger.shared.log("Join failed: \(fullErrorDetails(error))", level: .error, category: "Meet")
        }
    }

    func joinScheduledMeeting(_ scheduled: ScheduledMeeting) async {
        guard let index = scheduledMeetings.firstIndex(where: { $0.id == scheduled.id }) else {
            errorMessage = "Unable to find the scheduled meeting."
            return
        }

        var scheduledMeeting = scheduledMeetings[index]
        let now = Date()
        // Meeting activation is deterministic: scheduled meetings become join-eligible
        // exactly at their scheduled timestamp.
        guard now >= scheduledMeeting.scheduledAt else {
            errorMessage = "This meeting is scheduled for \(scheduledMeeting.scheduledAt.formatted(date: .abbreviated, time: .shortened)) and is not active yet."
            return
        }

        if scheduledMeeting.activationState != .active || scheduledMeeting.meetingId == nil {
            isBusy = true
            errorMessage = nil
            defer { isBusy = false }

            do {
                let session = try await resolver.createSession(with: nil)
                pendingCreatorHostAssignment = true
                scheduledMeeting.meetingId = session.meetingId
                scheduledMeeting.activationState = .active
                scheduledMeetings[index] = scheduledMeeting
                meetingIdInput = session.meetingId
                await transitionToLobby(session)
                DebugLogger.shared.log("Scheduled meeting activated at join time. meetingId=\(session.meetingId)", category: "Meet")
            } catch {
                phase = .failed
                errorMessage = error.localizedDescription
                DebugLogger.shared.log("Scheduled activation failed: \(error.localizedDescription)", level: .error, category: "Meet")
            }
            return
        }

        guard let activeMeetingID = scheduledMeeting.meetingId else {
            errorMessage = "Scheduled meeting is not active yet."
            return
        }

        meetingIdInput = activeMeetingID
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
        guard !isJoining else { return }
        guard let currentSession else { return }
        let trimmedDisplayName = displayNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDisplayName.isEmpty else {
            errorMessage = "Display name is required before joining."
            return
        }
        guard !lobbyState.isCheckingDevices, !lobbyState.isLoadingParticipants else {
            errorMessage = "Please wait for lobby checks to complete before joining."
            return
        }
        guard lobbyState.microphonePermission != .denied, lobbyState.cameraPermission != .denied else {
            errorMessage = "Microphone and camera permissions are required to join."
            return
        }
        guard !isMeetingLocked || canAccessAdminControls else {
            errorMessage = "This meeting is locked."
            return
        }
        let roomURL = await resolver.internalRoomURL(for: currentSession)
        if let validationError = validatePreJoin(session: currentSession, roomURL: roomURL) {
            errorMessage = validationError
            phase = .failed
            DebugLogger.shared.log("Blocked join by pre-join validation for meeting \(currentSession.meetingId): \(validationError)", level: .warning, category: "Meet")
            return
        }
        guard let roomURL else {
            errorMessage = "Meeting room was not found. Verify the meeting ID and try again."
            phase = .failed
            return
        }

        isJoining = true
        isBusy = true
        errorMessage = nil
        defer {
            isBusy = false
            isJoining = false
        }

        do {
            await leaveDailyRoom(reason: "pre-join reset")
            resetMeetingRuntimeStateForJoin()
            try await beginAndJoinSession(currentSession, roomURL: roomURL)
            phase = .inMeeting
            callKitManager.reportOutgoingCallStart(meetingID: currentSession.meetingId)
            callKitManager.updateConnected()
            await refreshDebugSnapshot()
        } catch {
            phase = .failed
            errorMessage = userFacingJoinErrorMessage(for: error)
            callKitManager.endCall()
            DebugLogger.shared.log("Failed to start Daily session. \(fullErrorDetails(error))", level: .error, category: "Meet")
            await refreshDebugSnapshot()
        }
    }

    func leaveMeeting() async {
        guard let currentSession else { return }
        callKitManager.endCall()
        await leaveDailyRoom(reason: "user leave")
        var cleanedSessionIDs: Set<String> = []
        // End `activeStartedSession` first because it represents the actively joined Daily lifecycle;
        // when `currentSession` differs (for example after session rotation), both need explicit cleanup.
        if let activeStartedSession {
            await resolver.endSession(activeStartedSession)
            cleanedSessionIDs.insert(activeStartedSession.sessionId)
        }
        if !cleanedSessionIDs.contains(currentSession.sessionId) {
            await resolver.endSession(currentSession)
        }
        self.activeStartedSession = nil
        phase = .ended
        self.currentSession = nil
        resetMeetingRuntimeStateForJoin()
        await refreshDebugSnapshot()
    }

    func endMeetingForEveryone() async {
        guard isCurrentUserHost else {
            errorMessage = "Only the host can end the meeting for everyone."
            return
        }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.endMeetingForAll, in: currentSession)
        await leaveMeeting()
    }

    func toggleMute() {
        Task { await setMicrophoneEnabled(!isMicrophoneMuted) }
    }

    func toggleCamera() {
        Task { await setCameraEnabled(!isCameraEnabled) }
    }

    func toggleScreenShare() {
        Task {
            guard isScreenShareAllowed || isCurrentUserAdmin else {
                await MainActor.run {
                    errorMessage = "Screen sharing is currently disabled by an admin."
                }
                return
            }
            await setScreenShareEnabled(!isScreenSharing)
        }
    }

    func setNoiseCancellationEnabled(_ enabled: Bool) {
        isNoiseCancellationEnabled = enabled
        activeAudioProcessingState = enabled ? "Noise suppression active" : "Disabled"
        sendRealtimePayload(.noiseCancellationChanged(isEnabled: enabled))
    }

    func setCaptionsEnabled(_ enabled: Bool) {
        isCaptionsEnabled = enabled
    }

    func appendCaptionLine(speaker: String, text: String, timestamp: Date = Date(), broadcast: Bool = false) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let line = MeetingCaptionLine(id: UUID().uuidString, speaker: speaker, text: text, timestamp: timestamp)
        captions.append(line)
        if captions.count > 200 { captions.removeFirst() }
        if broadcast {
            sendRealtimePayload(.caption(
                id: line.id,
                speaker: line.speaker,
                text: line.text,
                timestamp: line.timestamp.timeIntervalSince1970
            ))
        }
    }

    func setBackgroundEffect(_ effect: MeetingBackgroundEffect) {
        backgroundEffect = effect
        sendRealtimePayload(.backgroundEffectChanged(effect: effect.rawValue))
    }

    func sendReaction(_ emoji: String) {
        guard let localParticipantID else { return }
        let name = localParticipantDisplayName.isEmpty ? Self.guestDisplayName : localParticipantDisplayName
        let event = MeetingReactionEvent(
            id: UUID().uuidString,
            participantID: localParticipantID,
            participantName: name,
            emoji: emoji,
            createdAt: Date()
        )
        applyReactionEvent(event)
        sendRealtimePayload(.reaction(
            id: event.id,
            participantId: event.participantID,
            participantName: event.participantName,
            emoji: event.emoji,
            createdAt: event.createdAt.timeIntervalSince1970
        ))
    }

    func toggleRaiseHand() {
        guard let localParticipantID else { return }
        let isRaised = !raisedHandParticipantIDs.contains(localParticipantID)
        setHandRaised(participantID: localParticipantID, raised: isRaised)
        sendRealtimePayload(.handRaiseChanged(participantId: localParticipantID, isRaised: isRaised))
    }

    func setHandRaised(participantID: String, raised: Bool) {
        if raised {
            raisedHandParticipantIDs.insert(participantID)
        } else {
            raisedHandParticipantIDs.remove(participantID)
        }
        refreshParticipantsFromDaily()
    }

    func setPiPEnabled(_ enabled: Bool) {
        isPiPEnabled = enabled
        if enabled {
            piPController.start()
        } else {
            piPController.stop()
        }
        isPiPActive = piPController.isActive
    }

    func dismissCPUWarning(_ warningID: String) {
        cpuWarnings.removeAll { $0.id == warningID }
    }

    func sendMessage(_ text: String, threadId: String = "general") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard phase == .inMeeting else { return }
        guard isChatEnabled || isCurrentUserAdmin else {
            errorMessage = "Chat is currently disabled."
            return
        }
        let message = MeetingMessage(
            id: UUID().uuidString,
            threadId: threadId,
            senderName: localParticipantDisplayName.isEmpty ? Self.guestDisplayName : localParticipantDisplayName,
            text: trimmed,
            sentAt: Date(),
            isSystem: false,
            deliveryState: .sent,
            reactions: [:]
        )
        messages.append(message)
        sendRealtimePayload(.chat(
            id: message.id,
            threadId: threadId,
            senderName: message.senderName,
            text: message.text,
            sentAt: message.sentAt.timeIntervalSince1970
        ))
    }

    func reactToMessage(messageID: String, emoji: String) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
        messages[index].reactions[emoji, default: 0] += 1
        sendRealtimePayload(.messageReaction(messageId: messageID, emoji: emoji))
    }

    func addThread(named title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let threadID = "thread-\(UUID().uuidString)"
        chatThreads.append(.init(id: threadID, title: trimmed))
        sendRealtimePayload(.threadAdded(id: threadID, title: trimmed))
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

    func refreshDebugSnapshot() async {
        debugSnapshot = await resolver.fetchDebugSnapshot()
    }

    func muteAllParticipants() async {
        guard canAccessAdminControls else { return }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.muteAll, in: currentSession)
    }

    func setParticipantMuted(participantID: String, muted: Bool) async {
        guard canAccessAdminControls else { return }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.setParticipantMuted(participantId: participantID, muted: muted), in: currentSession)
    }

    func setParticipantVideoEnabled(participantID: String, enabled: Bool) async {
        guard canAccessAdminControls else { return }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.setParticipantVideoEnabled(participantId: participantID, enabled: enabled), in: currentSession)
    }

    func removeParticipant(participantID: String) async {
        guard canAccessAdminControls else { return }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.removeParticipant(participantId: participantID), in: currentSession)
    }

    func assignRole(participantID: String, role: MeetingParticipantRole) async {
        guard isCurrentUserHost else {
            errorMessage = "Only the host can assign admin roles."
            return
        }
        if participantID == hostParticipantID, role != .host {
            errorMessage = "Reassign host before removing host role."
            return
        }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.assignRole(participantId: participantID, role: role), in: currentSession)
        switch role {
        case .host:
            hostParticipantID = participantID
            adminParticipantIDs.remove(participantID)
        case .admin:
            adminParticipantIDs.insert(participantID)
        case .participant:
            adminParticipantIDs.remove(participantID)
        }
        sendRealtimePayload(.rolesUpdated(hostId: hostParticipantID, adminIds: Array(adminParticipantIDs)))
    }

    func setMeetingLocked(_ locked: Bool) async {
        guard canAccessAdminControls else { return }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.lockMeeting(locked), in: currentSession)
        isMeetingLocked = locked
        sendRealtimePayload(.meetingLockChanged(isLocked: locked))
    }

    func setChatEnabled(_ enabled: Bool) async {
        guard canAccessAdminControls else { return }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.setChatEnabled(enabled), in: currentSession)
        isChatEnabled = enabled
        sendRealtimePayload(.chatAvailabilityChanged(isEnabled: enabled))
    }

    func spotlightParticipant(_ participantID: String?) async {
        guard canAccessAdminControls else { return }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.spotlightParticipant(participantId: participantID), in: currentSession)
        spotlightedParticipantID = participantID
        sendRealtimePayload(.spotlightChanged(participantId: participantID))
    }

    func pinParticipant(_ participantID: String?) async {
        guard canAccessAdminControls else { return }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.pinParticipant(participantId: participantID), in: currentSession)
        pinnedParticipantID = participantID
        sendRealtimePayload(.pinChanged(participantId: participantID))
    }

    func setScreenShareAllowed(_ enabled: Bool) async {
        guard canAccessAdminControls else { return }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.setScreenShareEnabled(enabled), in: currentSession)
        isScreenShareAllowed = enabled
        if !enabled && isScreenSharing {
            await setScreenShareEnabled(false)
        }
        sendRealtimePayload(.screenShareAvailabilityChanged(isEnabled: enabled))
    }

    func createBreakoutRoom(named name: String) async {
        guard canAccessAdminControls else {
            errorMessage = "Only host or admins can manage breakout rooms."
            return
        }
        guard let currentSession else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await resolver.applyAdminAction(.createBreakoutRoom(name: trimmed), in: currentSession)
        let room = MeetingBreakoutRoom(id: UUID().uuidString, name: trimmed, participantIds: [])
        breakoutRooms.append(room)
        await syncBreakoutRooms()
        sendRealtimePayload(.breakoutRoomsUpdated(rooms: breakoutRooms))
    }

    func assignParticipant(_ participantID: String, to roomID: String?) async {
        guard canAccessAdminControls else {
            errorMessage = "Only host or admins can move participants between breakout rooms."
            return
        }
        guard let currentSession else { return }
        await resolver.applyAdminAction(.assignParticipantToBreakout(participantId: participantID, roomId: roomID), in: currentSession)
        breakoutRooms = breakoutRooms.map { room in
            var updated = room
            updated.participantIds.removeAll { $0 == participantID }
            if room.id == roomID {
                updated.participantIds.append(participantID)
            }
            return updated
        }
        await syncBreakoutRooms()
        sendRealtimePayload(.breakoutRoomsUpdated(rooms: breakoutRooms))
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
        await leaveDailyRoom(reason: "transition to lobby reset")
        if let activeStartedSession {
            await resolver.endSession(activeStartedSession)
            self.activeStartedSession = nil
        }
        currentSession = session
        meetingIdInput = session.meetingId
        phase = .lobby
        callKitManager.reportIncomingCall(meetingID: session.meetingId)
        summary = MeetingSummaryState()
        diagnostics = MeetingDiagnosticsState()
        participants = []
        participantVideoTracks = [:]
        participantScreenShareTracks = [:]
        breakoutRooms = []
        messages = []
        chatThreads = [MeetingChatThread(id: "general", title: "General")]
        participantRoles = [:]
        localParticipantID = nil
        localParticipantDisplayName = ""
        hostParticipantID = nil
        adminParticipantIDs = []
        isMeetingLocked = false
        isChatEnabled = true
        isScreenShareAllowed = true
        spotlightedParticipantID = nil
        pinnedParticipantID = nil
        activeScreenShareParticipantID = nil
        captions = []
        isCaptionsEnabled = false
        reactions = []
        raisedHandParticipantIDs = []
        cpuWarnings = []
        networkQuality = .good
        isNoiseCancellationEnabled = false
        activeAudioProcessingState = "Disabled"
        backgroundEffect = .off
        isPiPEnabled = false
        isPiPActive = false
        lastBroadcastNetworkSignature = ""
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
        // Fallback builds cannot reference Daily's OutboundMediaType, so string keys
        // are used only to describe the attempted toggle in diagnostic messaging.
        await setInputEnabled(["microphone": enabled])
        #endif
    }

    private func setCameraEnabled(_ enabled: Bool) async {
        #if canImport(Daily)
        await setInputEnabled([.camera: enabled])
        #else
        // Fallback builds cannot reference Daily's OutboundMediaType, so string keys
        // are used only to describe the attempted toggle in diagnostic messaging.
        await setInputEnabled(["camera": enabled])
        #endif
    }

    private func setScreenShareEnabled(_ enabled: Bool) async {
        #if canImport(Daily)
        await setInputEnabled([.screenVideo: enabled])
        #else
        // Fallback builds cannot reference Daily's OutboundMediaType, so string keys
        // are used only to describe the attempted toggle in diagnostic messaging.
        await setInputEnabled(["screenVideo": enabled])
        #endif
        isScreenSharing = enabled
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
        // Daily types are unavailable in this build; we keep string keys only for
        // fallback diagnostics so the UI can surface which input toggle was requested.
        let inputNames = inputs.keys.sorted().joined(separator: ", ")
        guard !inputNames.isEmpty else { return }
        errorMessage = "Daily SDK is unavailable, so \(inputNames) state cannot be updated."
        DebugLogger.shared.log("\(inputNames) update blocked because Daily SDK is unavailable.", level: .warning, category: "Meet")
    }
    #endif

    private func leaveDailyRoom(reason: String) async {
        #if canImport(Daily)
        guard let callClient else { return }
        DebugLogger.shared.log("Destroying Daily call client (\(reason)).", level: .debug, category: "Meet")
        defer {
            callClient.delegate = nil
            self.callClient = nil
            DebugLogger.shared.log("Daily call client destroyed.", level: .debug, category: "Meet")
        }
        do {
            try await callClient.stopLocalAudioLevelObserver()
            try await callClient.stopRemoteParticipantsAudioLevelObserver()
            try await callClient.leave()
        } catch {
            DebugLogger.shared.log("Daily leave failed during \(reason). \(fullErrorDetails(error))", level: .warning, category: "Meet")
        }
        #endif
    }

    private func joinDailyRoom(url: URL, session: MeetingSession) async throws {
        #if canImport(Daily)
        let callClient = try await createFreshCallClient(session: session)
        let trimmedDisplayName = displayNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDisplayName.isEmpty {
            callClient.set(username: trimmedDisplayName, completion: nil)
        }
        let joinToken: MeetingToken?
        if let meetingToken = session.meetingToken?.trimmingCharacters(in: .whitespacesAndNewlines),
           !meetingToken.isEmpty {
            joinToken = MeetingToken(stringValue: meetingToken)
        } else {
            joinToken = nil
        }
        let settings = ClientSettingsUpdate(
            inputs: .set(
                camera: .set(isEnabled: .set(isCameraEnabled)),
                microphone: .set(isEnabled: .set(!isMicrophoneMuted))
            )
        )
        DebugLogger.shared.log("Daily join attempt meeting=\(session.meetingId) session=\(session.sessionId) trace=\(session.debugTraceId) url=\(redactedURLString(url))", level: .info, category: "Meet")
        do {
            try await callClient.join(url: url, token: joinToken, settings: settings)
            DebugLogger.shared.log("Daily join success meeting=\(session.meetingId) session=\(session.sessionId) trace=\(session.debugTraceId)", level: .info, category: "Meet")
            refreshParticipantsFromDaily()
        } catch {
            DebugLogger.shared.log("Daily join failed meeting=\(session.meetingId) session=\(session.sessionId) trace=\(session.debugTraceId). \(fullErrorDetails(error))", level: .error, category: "Meet")
            throw error
        }
        #else
        throw NSError(domain: "Meet", code: -1, userInfo: [NSLocalizedDescriptionKey: "Daily SDK is unavailable in this build."])
        #endif
    }

    #if canImport(Daily)
    private func createFreshCallClient(session: MeetingSession) async throws -> CallClient {
        DebugLogger.shared.log(
            "Preparing Daily call client before join meeting=\(session.meetingId) session=\(session.sessionId) trace=\(session.debugTraceId) existingClient=\(callClient != nil)",
            level: .debug,
            category: "Meet"
        )
        if callClient != nil {
            await leaveDailyRoom(reason: "force fresh client before join")
        }
        let callClient = CallClient()
        callClient.delegate = self
        self.callClient = callClient
        DebugLogger.shared.log("Daily call client created meeting=\(session.meetingId) session=\(session.sessionId) trace=\(session.debugTraceId)", level: .debug, category: "Meet")
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
        participantScreenShareTracks = Dictionary(uniqueKeysWithValues: sortedParticipants.compactMap { participant in
            guard let track = participant.media?.screenVideo.track else { return nil }
            return (participantIDString(participant), track)
        })
        activeScreenShareParticipantID = sortedParticipants
            .first(where: { $0.media?.screenVideo.state == .playable })
            .map { participantIDString($0) }

        let currentLocalParticipant = sortedParticipants.first(where: { $0.info.isLocal })
        let currentLocalParticipantID = currentLocalParticipant.map { participantIDString($0) }
        localParticipantID = currentLocalParticipantID
        localParticipantDisplayName = currentLocalParticipant.map(participantDisplayName) ?? ""
        if pendingCreatorHostAssignment, let currentLocalParticipantID {
            hostParticipantID = currentLocalParticipantID
            pendingCreatorHostAssignment = false
            sendRealtimePayload(.rolesUpdated(hostId: hostParticipantID, adminIds: Array(adminParticipantIDs)))
        }

        participants = sortedParticipants.map { participant in
            let participantID = participantIDString(participant)
            let role: MeetingParticipantRole
            if participantID == hostParticipantID {
                role = .host
            } else if adminParticipantIDs.contains(participantID) {
                role = .admin
            } else {
                role = .participant
            }
            let existingParticipant = participants.first(where: { $0.id == participantID })
            return MeetingParticipant(
                id: participantID,
                displayName: participantDisplayName(participant),
                joinedAt: existingParticipant?.joinedAt ?? Date(),
                isSpeaking: participantID == activeSpeakerID,
                isMuted: participant.media?.microphone.state != .playable,
                hasVideo: participant.media?.camera.state == .playable,
                isScreenSharing: participant.media?.screenVideo.state == .playable,
                role: role,
                breakoutRoomID: existingParticipant?.breakoutRoomID,
                isHandRaised: raisedHandParticipantIDs.contains(participantID),
                networkQuality: existingParticipant?.networkQuality ?? networkQuality
            )
        }
    }

    private nonisolated func participantDisplayName(_ participant: Participant) -> String {
        let trimmed = participant.info.username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }
        return Self.guestDisplayName
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
                isSystem: true,
                deliveryState: .delivered,
                reactions: [:]
            )
        )
    }

    private func applyReactionEvent(_ event: MeetingReactionEvent) {
        reactions.append(event)
        if reactions.count > 40 { reactions.removeFirst() }
    }

    private func addCPUWarning(message: String, action: String) {
        let warning = MeetingCPUWarning(
            id: UUID().uuidString,
            message: message,
            suggestedAction: action,
            createdAt: Date()
        )
        cpuWarnings.append(warning)
        if cpuWarnings.count > 10 { cpuWarnings.removeFirst() }
    }

    private func updateDerivedNetworkQuality() {
        let latency = diagnostics.latencyMs
        let packetLoss = diagnostics.packetLossPercent
        if packetLoss >= 8 || latency >= 600 {
            networkQuality = .poor
        } else if packetLoss >= 4 || latency >= 300 {
            networkQuality = .fair
        } else if packetLoss >= 1 || latency >= 140 {
            networkQuality = .good
        } else {
            networkQuality = .excellent
        }
        diagnostics.networkQuality = networkQuality.label
        if networkQuality == .poor {
            let alreadyHasConnectionWarning = cpuWarnings.contains {
                $0.message == Self.poorConnectionWarningMessage
            }
            if !alreadyHasConnectionWarning {
                addCPUWarning(message: Self.poorConnectionWarningMessage, action: "Turn off camera or close background apps.")
            }
        }
    }

    private enum RealtimePayload: Codable {
        case chat(id: String, threadId: String, senderName: String, text: String, sentAt: TimeInterval)
        case threadAdded(id: String, title: String)
        case rolesUpdated(hostId: String?, adminIds: [String])
        case meetingLockChanged(isLocked: Bool)
        case chatAvailabilityChanged(isEnabled: Bool)
        case spotlightChanged(participantId: String?)
        case pinChanged(participantId: String?)
        case screenShareAvailabilityChanged(isEnabled: Bool)
        case breakoutRoomsUpdated(rooms: [MeetingBreakoutRoom])
        case reaction(id: String, participantId: String, participantName: String, emoji: String, createdAt: TimeInterval)
        case handRaiseChanged(participantId: String, isRaised: Bool)
        case caption(id: String, speaker: String, text: String, timestamp: TimeInterval)
        case messageReaction(messageId: String, emoji: String)
        case networkQualityUpdated(quality: Int, latencyMs: Int, packetLossPercent: Double)
        case cpuWarning(message: String, action: String, createdAt: TimeInterval)
        case backgroundEffectChanged(effect: String)
        case noiseCancellationChanged(isEnabled: Bool)

        enum CodingKeys: String, CodingKey {
            case type
            case id
            case threadId
            case senderName
            case text
            case sentAt
            case title
            case hostId
            case adminIds
            case isLocked
            case isEnabled
            case participantId
            case participantName
            case emoji
            case createdAt
            case isRaised
            case speaker
            case timestamp
            case messageId
            case quality
            case latencyMs
            case packetLossPercent
            case message
            case action
            case effect
            case rooms
        }

        enum PayloadType: String, Codable {
            case chat
            case threadAdded
            case rolesUpdated
            case meetingLockChanged
            case chatAvailabilityChanged
            case spotlightChanged
            case pinChanged
            case screenShareAvailabilityChanged
            case breakoutRoomsUpdated
            case reaction
            case handRaiseChanged
            case caption
            case messageReaction
            case networkQualityUpdated
            case cpuWarning
            case backgroundEffectChanged
            case noiseCancellationChanged
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            switch try container.decode(PayloadType.self, forKey: .type) {
            case .chat:
                self = .chat(
                    id: try container.decode(String.self, forKey: .id),
                    threadId: try container.decode(String.self, forKey: .threadId),
                    senderName: try container.decode(String.self, forKey: .senderName),
                    text: try container.decode(String.self, forKey: .text),
                    sentAt: try container.decode(TimeInterval.self, forKey: .sentAt)
                )
            case .threadAdded:
                self = .threadAdded(
                    id: try container.decode(String.self, forKey: .id),
                    title: try container.decode(String.self, forKey: .title)
                )
            case .rolesUpdated:
                self = .rolesUpdated(
                    hostId: try container.decodeIfPresent(String.self, forKey: .hostId),
                    adminIds: try container.decode([String].self, forKey: .adminIds)
                )
            case .meetingLockChanged:
                self = .meetingLockChanged(isLocked: try container.decode(Bool.self, forKey: .isLocked))
            case .chatAvailabilityChanged:
                self = .chatAvailabilityChanged(isEnabled: try container.decode(Bool.self, forKey: .isEnabled))
            case .spotlightChanged:
                self = .spotlightChanged(participantId: try container.decodeIfPresent(String.self, forKey: .participantId))
            case .pinChanged:
                self = .pinChanged(participantId: try container.decodeIfPresent(String.self, forKey: .participantId))
            case .screenShareAvailabilityChanged:
                self = .screenShareAvailabilityChanged(isEnabled: try container.decode(Bool.self, forKey: .isEnabled))
            case .breakoutRoomsUpdated:
                self = .breakoutRoomsUpdated(rooms: try container.decode([MeetingBreakoutRoom].self, forKey: .rooms))
            case .reaction:
                self = .reaction(
                    id: try container.decode(String.self, forKey: .id),
                    participantId: try container.decode(String.self, forKey: .participantId),
                    participantName: try container.decode(String.self, forKey: .participantName),
                    emoji: try container.decode(String.self, forKey: .emoji),
                    createdAt: try container.decode(TimeInterval.self, forKey: .createdAt)
                )
            case .handRaiseChanged:
                self = .handRaiseChanged(
                    participantId: try container.decode(String.self, forKey: .participantId),
                    isRaised: try container.decode(Bool.self, forKey: .isRaised)
                )
            case .caption:
                self = .caption(
                    id: try container.decode(String.self, forKey: .id),
                    speaker: try container.decode(String.self, forKey: .speaker),
                    text: try container.decode(String.self, forKey: .text),
                    timestamp: try container.decode(TimeInterval.self, forKey: .timestamp)
                )
            case .messageReaction:
                self = .messageReaction(
                    messageId: try container.decode(String.self, forKey: .messageId),
                    emoji: try container.decode(String.self, forKey: .emoji)
                )
            case .networkQualityUpdated:
                self = .networkQualityUpdated(
                    quality: try container.decode(Int.self, forKey: .quality),
                    latencyMs: try container.decode(Int.self, forKey: .latencyMs),
                    packetLossPercent: try container.decode(Double.self, forKey: .packetLossPercent)
                )
            case .cpuWarning:
                self = .cpuWarning(
                    message: try container.decode(String.self, forKey: .message),
                    action: try container.decode(String.self, forKey: .action),
                    createdAt: try container.decode(TimeInterval.self, forKey: .createdAt)
                )
            case .backgroundEffectChanged:
                self = .backgroundEffectChanged(effect: try container.decode(String.self, forKey: .effect))
            case .noiseCancellationChanged:
                self = .noiseCancellationChanged(isEnabled: try container.decode(Bool.self, forKey: .isEnabled))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .chat(id, threadId, senderName, text, sentAt):
                try container.encode(PayloadType.chat, forKey: .type)
                try container.encode(id, forKey: .id)
                try container.encode(threadId, forKey: .threadId)
                try container.encode(senderName, forKey: .senderName)
                try container.encode(text, forKey: .text)
                try container.encode(sentAt, forKey: .sentAt)
            case let .threadAdded(id, title):
                try container.encode(PayloadType.threadAdded, forKey: .type)
                try container.encode(id, forKey: .id)
                try container.encode(title, forKey: .title)
            case let .rolesUpdated(hostId, adminIds):
                try container.encode(PayloadType.rolesUpdated, forKey: .type)
                try container.encodeIfPresent(hostId, forKey: .hostId)
                try container.encode(adminIds, forKey: .adminIds)
            case let .meetingLockChanged(isLocked):
                try container.encode(PayloadType.meetingLockChanged, forKey: .type)
                try container.encode(isLocked, forKey: .isLocked)
            case let .chatAvailabilityChanged(isEnabled):
                try container.encode(PayloadType.chatAvailabilityChanged, forKey: .type)
                try container.encode(isEnabled, forKey: .isEnabled)
            case let .spotlightChanged(participantId):
                try container.encode(PayloadType.spotlightChanged, forKey: .type)
                try container.encodeIfPresent(participantId, forKey: .participantId)
            case let .pinChanged(participantId):
                try container.encode(PayloadType.pinChanged, forKey: .type)
                try container.encodeIfPresent(participantId, forKey: .participantId)
            case let .screenShareAvailabilityChanged(isEnabled):
                try container.encode(PayloadType.screenShareAvailabilityChanged, forKey: .type)
                try container.encode(isEnabled, forKey: .isEnabled)
            case let .breakoutRoomsUpdated(rooms):
                try container.encode(PayloadType.breakoutRoomsUpdated, forKey: .type)
                try container.encode(rooms, forKey: .rooms)
            case let .reaction(id, participantId, participantName, emoji, createdAt):
                try container.encode(PayloadType.reaction, forKey: .type)
                try container.encode(id, forKey: .id)
                try container.encode(participantId, forKey: .participantId)
                try container.encode(participantName, forKey: .participantName)
                try container.encode(emoji, forKey: .emoji)
                try container.encode(createdAt, forKey: .createdAt)
            case let .handRaiseChanged(participantId, isRaised):
                try container.encode(PayloadType.handRaiseChanged, forKey: .type)
                try container.encode(participantId, forKey: .participantId)
                try container.encode(isRaised, forKey: .isRaised)
            case let .caption(id, speaker, text, timestamp):
                try container.encode(PayloadType.caption, forKey: .type)
                try container.encode(id, forKey: .id)
                try container.encode(speaker, forKey: .speaker)
                try container.encode(text, forKey: .text)
                try container.encode(timestamp, forKey: .timestamp)
            case let .messageReaction(messageId, emoji):
                try container.encode(PayloadType.messageReaction, forKey: .type)
                try container.encode(messageId, forKey: .messageId)
                try container.encode(emoji, forKey: .emoji)
            case let .networkQualityUpdated(quality, latencyMs, packetLossPercent):
                try container.encode(PayloadType.networkQualityUpdated, forKey: .type)
                try container.encode(quality, forKey: .quality)
                try container.encode(latencyMs, forKey: .latencyMs)
                try container.encode(packetLossPercent, forKey: .packetLossPercent)
            case let .cpuWarning(message, action, createdAt):
                try container.encode(PayloadType.cpuWarning, forKey: .type)
                try container.encode(message, forKey: .message)
                try container.encode(action, forKey: .action)
                try container.encode(createdAt, forKey: .createdAt)
            case let .backgroundEffectChanged(effect):
                try container.encode(PayloadType.backgroundEffectChanged, forKey: .type)
                try container.encode(effect, forKey: .effect)
            case let .noiseCancellationChanged(isEnabled):
                try container.encode(PayloadType.noiseCancellationChanged, forKey: .type)
                try container.encode(isEnabled, forKey: .isEnabled)
            }
        }
    }

    private func sendRealtimePayload(_ payload: RealtimePayload) {
        guard let callClient else { return }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        callClient.sendAppMessage(json: data, to: .all, completion: nil)
    }

    private func applyRealtimePayload(_ payload: RealtimePayload, from participantId: String?) {
        switch payload {
        case let .chat(id, threadId, senderName, text, sentAt):
            // Ignore duplicates because app messages can be retried/replayed by transport reconnects.
            if messages.contains(where: { $0.id == id }) { return }
            let threadExists = chatThreads.contains { $0.id == threadId }
            if !threadExists {
                chatThreads.append(.init(id: threadId, title: "General"))
            }
            messages.append(.init(id: id, threadId: threadId, senderName: senderName, text: text, sentAt: Date(timeIntervalSince1970: sentAt), isSystem: false, deliveryState: .delivered, reactions: [:]))
        case let .threadAdded(id, title):
            if !chatThreads.contains(where: { $0.id == id }) {
                chatThreads.append(.init(id: id, title: title))
            }
        case let .rolesUpdated(hostId, adminIds):
            hostParticipantID = hostId
            adminParticipantIDs = Set(adminIds)
            participantRoles = Dictionary(uniqueKeysWithValues: adminIds.map { ($0, .admin) })
            if let hostId {
                participantRoles[hostId] = .host
            }
            // Local sender already has up-to-date role state; remote updates should force a participant refresh.
            if let participantId, participantId != localParticipantID {
                refreshParticipantsFromDaily()
            }
        case let .meetingLockChanged(isLocked):
            isMeetingLocked = isLocked
        case let .chatAvailabilityChanged(isEnabled):
            isChatEnabled = isEnabled
        case let .spotlightChanged(participantId):
            spotlightedParticipantID = participantId
        case let .pinChanged(participantId):
            pinnedParticipantID = participantId
        case let .screenShareAvailabilityChanged(isEnabled):
            isScreenShareAllowed = isEnabled
        case let .breakoutRoomsUpdated(rooms):
            breakoutRooms = rooms
        case let .reaction(id, participantId, participantName, emoji, createdAt):
            applyReactionEvent(.init(id: id, participantID: participantId, participantName: participantName, emoji: emoji, createdAt: Date(timeIntervalSince1970: createdAt)))
        case let .handRaiseChanged(participantId, isRaised):
            setHandRaised(participantID: participantId, raised: isRaised)
        case let .caption(id, speaker, text, timestamp):
            if !captions.contains(where: { $0.id == id }) {
                appendCaptionLine(speaker: speaker, text: text, timestamp: Date(timeIntervalSince1970: timestamp))
            }
        case let .messageReaction(messageId, emoji):
            guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
            messages[index].reactions[emoji, default: 0] += 1
        case let .networkQualityUpdated(quality, latencyMs, packetLossPercent):
            diagnostics.latencyMs = latencyMs
            diagnostics.packetLossPercent = packetLossPercent
            networkQuality = MeetingNetworkQuality(rawValue: quality) ?? .good
            diagnostics.networkQuality = networkQuality.label
        case let .cpuWarning(message, action, createdAt):
            addCPUWarning(message: message, action: action)
        case let .backgroundEffectChanged(effect):
            backgroundEffect = MeetingBackgroundEffect(rawValue: effect) ?? .off
        case let .noiseCancellationChanged(isEnabled):
            isNoiseCancellationEnabled = isEnabled
            activeAudioProcessingState = isEnabled ? "Noise suppression active" : "Disabled"
        }
    }
    #endif

    private func resetMeetingRuntimeStateForJoin() {
        participants = []
        participantVideoTracks = [:]
        participantScreenShareTracks = [:]
        breakoutRooms = []
        participantRoles = [:]
        localParticipantID = nil
        localParticipantDisplayName = ""
        activeSpeakerID = nil
        hostParticipantID = nil
        adminParticipantIDs = []
        isMeetingLocked = false
        isChatEnabled = true
        isScreenShareAllowed = true
        spotlightedParticipantID = nil
        pinnedParticipantID = nil
        activeScreenShareParticipantID = nil
        messages = []
        chatThreads = [MeetingChatThread(id: "general", title: "General")]
        diagnostics.connectionState = "Unknown"
        diagnostics.networkQuality = "Unknown"
        diagnostics.latencyMs = 0
        diagnostics.packetLossPercent = 0
        captions = []
        isCaptionsEnabled = false
        reactions = []
        raisedHandParticipantIDs = []
        cpuWarnings = []
        networkQuality = .good
        isNoiseCancellationEnabled = false
        activeAudioProcessingState = "Disabled"
        backgroundEffect = .off
        isPiPEnabled = false
        isPiPActive = false
        lastBroadcastNetworkSignature = ""
        piPController.stop()
    }

    private func validatePreJoin(session: MeetingSession, roomURL: URL?) -> String? {
        let roomName = session.roomName.trimmingCharacters(in: .whitespacesAndNewlines)
        if roomName.isEmpty {
            return "Meeting session is invalid. Please rejoin from the meeting list."
        }

        guard let roomURL else {
            return "Meeting room was not found. Verify the meeting ID and try again."
        }
        guard isValidDailyRoomURL(roomURL) else {
            return "Meeting room configuration is invalid. Please request a new meeting link."
        }

        guard session.isJoinable else {
            return "You are not authorized to join this meeting."
        }

        if session.requiresMeetingToken {
            guard let meetingToken = session.meetingToken,
                  MeetingSession.isLikelyValidMeetingToken(meetingToken) else {
                return "Meeting authorization is missing or invalid. Please refresh and try again."
            }
        }

        return nil
    }

    private func isValidDailyRoomURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased() else { return false }
        return host == "daily.co" || host.hasSuffix(".daily.co")
    }

    private func userFacingJoinErrorMessage(for error: any Swift.Error) -> String {
        if let serviceError = error as? DailyService.ServiceError {
            if case let .requestFailed(statusCode, _) = serviceError, statusCode == 401 || statusCode == 403 {
                return "You are not authorized to join this meeting."
            }
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedMessage = message.lowercased()
        // Fallback to message-based detection because Daily SDK callback errors are not always bridged
        // with stable typed status codes across all failure paths.
        if Self.unauthorizedJoinErrorMarkers.contains(where: { lowercasedMessage.contains($0) }) {
            return "You are not authorized to join this meeting."
        }
        if lowercasedMessage.contains("token")
            && (lowercasedMessage.contains("invalid")
                || lowercasedMessage.contains("expired")
                || lowercasedMessage.contains("missing")) {
            return "Meeting authorization is invalid or expired. Please refresh and try again."
        }
        return message
    }

    private func fullErrorDetails(_ errorPayload: Any) -> String {
        if let error = errorPayload as? any Swift.Error {
            let nsError = error as NSError
            let reflectedError = sanitizePotentialSecretContent(String(reflecting: error))
            let localized = sanitizePotentialSecretContent(error.localizedDescription)
            let userInfo = sanitizedUserInfoDescription(nsError.userInfo)
            return "error=\(reflectedError) domain=\(nsError.domain) code=\(nsError.code) localized=\"\(localized)\" userInfo=\(userInfo)"
        }

        let rawDescription = sanitizePotentialSecretContent(String(describing: errorPayload))
        return "nonErrorType=\(String(describing: type(of: errorPayload))) raw=\"\(rawDescription)\""
    }

    private func beginAndJoinSession(_ session: MeetingSession, roomURL: URL) async throws {
        if let activeStartedSession, activeStartedSession.sessionId != session.sessionId {
            await resolver.endSession(activeStartedSession)
            self.activeStartedSession = nil
        }
        await resolver.beginSession(session)
        activeStartedSession = session
        do {
            try await joinDailyRoom(url: roomURL, session: session)
        } catch {
            await leaveDailyRoom(reason: "join failure cleanup")
            await resolver.endSession(session)
            if activeStartedSession?.sessionId == session.sessionId {
                activeStartedSession = nil
            }
            throw error
        }
    }

    private func redactedURLString(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return sanitizePotentialSecretContent(url.absoluteString)
        }
        if var queryItems = components.queryItems {
            queryItems = queryItems.map { item in
                let lowercasedName = item.name.lowercased()
                if lowercasedName == DailyService.dailyTokenParameterName || Self.sensitiveQueryParameterNames.contains(lowercasedName) {
                    return URLQueryItem(name: item.name, value: "<redacted>")
                }
                return URLQueryItem(name: item.name, value: sanitizePotentialSecretContent(item.value ?? ""))
            }
            components.queryItems = queryItems
        }
        return components.url?.absoluteString ?? sanitizePotentialSecretContent(url.absoluteString)
    }

    private func sanitizedUserInfoDescription(_ userInfo: [String: Any]) -> String {
        guard !userInfo.isEmpty else { return "[:]" }
        var sanitized: [String: String] = [:]
        for (key, value) in userInfo {
            let lowercasedKey = key.lowercased()
            if Self.sensitiveUserInfoKeyFragments.contains(where: { lowercasedKey.contains($0) }) {
                sanitized[key] = "<redacted>"
                continue
            }
            sanitized[key] = sanitizePotentialSecretContent(String(describing: value))
        }
        return String(describing: sanitized)
    }

    private func sanitizePotentialSecretContent(_ value: String) -> String {
        var sanitized = value
        sanitized = sanitized.replacingOccurrences(
            of: Self.sensitiveURLValuePattern,
            with: "$1<redacted>",
            options: .regularExpression
        )
        let fragmentTokenPattern = #"(?i)([#&](?:token|access_token|refresh_token|session|session_token|client_secret|api_key|apikey|key)=)[^&\s]+"#
        sanitized = sanitized.replacingOccurrences(
            of: fragmentTokenPattern,
            with: "$1<redacted>",
            options: .regularExpression
        )
        let bearerPattern = #"(?i)(\bbearer\s+)[^\s,;]+"#
        sanitized = sanitized.replacingOccurrences(
            of: bearerPattern,
            with: "$1<redacted>",
            options: .regularExpression
        )
        return sanitized
    }
}

#if canImport(Daily)
extension MeetingStateManager: CallClientDelegate {
    nonisolated private func isStaleCallback(callClient: CallClient) async -> Bool {
        await MainActor.run {
            // A nil active client means there is no current session, so any callback
            // arriving now must belong to an old/destroyed client.
            guard let current = self.callClient else { return true }
            return current !== callClient
        }
    }

    nonisolated func callClient(_ callClient: CallClient, callStateUpdated state: CallState) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
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
            updateDerivedNetworkQuality()
            let networkStateSignature = "\(networkQuality.rawValue)-\(diagnostics.latencyMs)-\(diagnostics.packetLossPercent)"
            if lastBroadcastNetworkSignature != networkStateSignature {
                lastBroadcastNetworkSignature = networkStateSignature
                sendRealtimePayload(.networkQualityUpdated(quality: networkQuality.rawValue, latencyMs: diagnostics.latencyMs, packetLossPercent: diagnostics.packetLossPercent))
            }
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, participantJoined participant: Participant) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            appendSystemMessage("\(participantDisplayName(participant)) joined.")
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, participantLeft participant: Participant, withReason reason: ParticipantLeftReason) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
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
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, activeSpeakerChanged activeSpeaker: Participant?) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            activeSpeakerID = activeSpeaker.map { participantIDString($0) }
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, inputsUpdated inputs: InputSettings) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            isCameraEnabled = inputs.camera.isEnabled
            isMicrophoneMuted = !inputs.microphone.isEnabled
            isScreenSharing = inputs.screenVideo.isEnabled
            activeAudioProcessingState = isNoiseCancellationEnabled && inputs.microphone.isEnabled ? "Noise suppression active" : "Disabled"
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, appMessageAsJson jsonData: Data, from participantId: ParticipantID) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            guard let payload = try? JSONDecoder().decode(RealtimePayload.self, from: jsonData) else { return }
            applyRealtimePayload(payload, from: "\(participantId)")
        }
    }

    nonisolated func callClient(_ callClient: CallClient, appMessageFromRestApiAsJson jsonData: Data) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            guard let payload = try? JSONDecoder().decode(RealtimePayload.self, from: jsonData) else { return }
            applyRealtimePayload(payload, from: nil)
        }
    }

    nonisolated func callClientDidDetectStartOfSystemBroadcast(_ callClient: CallClient) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            await setScreenShareEnabled(true)
        }
    }

    nonisolated func callClientDidDetectEndOfSystemBroadcast(_ callClient: CallClient) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            await setScreenShareEnabled(false)
        }
    }

    nonisolated func callClient(_ callClient: CallClient, error: CallClientError) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            DebugLogger.shared.log("Daily delegate error callback received.", level: .error, category: "Meet")
            errorMessage = userFacingJoinErrorMessage(for: error)
            addCPUWarning(message: Self.dailyErrorWarningMessage, action: Self.dailyErrorWarningAction)
            sendRealtimePayload(.cpuWarning(message: Self.dailyErrorWarningMessage, action: Self.dailyErrorWarningAction, createdAt: Date().timeIntervalSince1970))
            DebugLogger.shared.log("Daily delegate error payload: \(fullErrorDetails(error))", level: .error, category: "Meet")
        }
    }
}
#endif

typealias MeetSessionController = MeetingStateManager
