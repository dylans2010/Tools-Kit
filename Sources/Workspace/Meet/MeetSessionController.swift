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
    private var activeStartedSession: MeetingSession?

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
        guard !lobbyState.isCheckingDevices, !lobbyState.isLoadingParticipants else {
            errorMessage = "Please wait for lobby checks to complete before joining."
            return
        }
        guard lobbyState.microphonePermission != .denied, lobbyState.cameraPermission != .denied else {
            errorMessage = "Microphone and camera permissions are required to join."
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
            await refreshDebugSnapshot()
        } catch {
            phase = .failed
            errorMessage = userFacingJoinErrorMessage(for: error)
            DebugLogger.shared.log("Failed to start Daily session. \(fullErrorDetails(error))", level: .error, category: "Meet")
            await refreshDebugSnapshot()
        }
    }

    func leaveMeeting() async {
        guard let currentSession else { return }
        await leaveDailyRoom(reason: "user leave")
        if let activeStartedSession {
            await resolver.endSession(activeStartedSession)
            self.activeStartedSession = nil
        } else {
            await resolver.endSession(currentSession)
        }
        phase = .ended
        self.currentSession = nil
        resetMeetingRuntimeStateForJoin()
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
        await leaveDailyRoom(reason: "transition to lobby reset")
        if let activeStartedSession {
            await resolver.endSession(activeStartedSession)
            self.activeStartedSession = nil
        }
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

    private func resetMeetingRuntimeStateForJoin() {
        participants = []
        participantVideoTracks = [:]
        breakoutRooms = []
        participantRoles = [:]
        localParticipantID = nil
        localParticipantDisplayName = ""
        activeSpeakerID = nil
        messages = []
        chatThreads = []
        diagnostics.connectionState = "Unknown"
        diagnostics.networkQuality = "Unknown"
        diagnostics.latencyMs = 0
        diagnostics.packetLossPercent = 0
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
            refreshParticipantsFromDaily()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, error: CallClientError) {
        Task { @MainActor in
            guard !(await isStaleCallback(callClient: callClient)) else { return }
            DebugLogger.shared.log("Daily delegate error callback received.", level: .error, category: "Meet")
            errorMessage = userFacingJoinErrorMessage(for: error)
            DebugLogger.shared.log("Daily delegate error payload: \(fullErrorDetails(error))", level: .error, category: "Meet")
        }
    }
}
#endif

typealias MeetSessionController = MeetingStateManager
