import Foundation

#if canImport(Daily)
import Daily
#endif

struct DailyCallParticipant: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let isLocal: Bool
    let isAudioPlayable: Bool
    let isVideoPlayable: Bool
}

@MainActor
final class DailyCallBackend: NSObject, ObservableObject {
    private let maxEventLogEntries = 100

    @Published var roomURL = ""
    @Published var meetingToken = ""
    @Published var username = ""
    @Published var isJoining = false
    @Published var isJoined = false
    @Published var isMicrophoneEnabled = false
    @Published var isCameraEnabled = false
    @Published var callStateDescription = "left"
    @Published var networkQualityDescription = "unknown"
    @Published var recordingStateDescription = "unknown"
    @Published var participants: [DailyCallParticipant] = []
    @Published var activeSpeakerID: String?
    @Published var errorMessage: String?
    @Published var eventLog: [String] = []

    #if canImport(Daily)
    @Published private(set) var localVideoTrack: VideoTrack?
    @Published private(set) var activeSpeakerVideoTrack: VideoTrack?
    private var callClient: CallClient?
    #endif

    func join() async {
        errorMessage = nil

        guard let room = URL(string: roomURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              room.scheme?.lowercased() == "https",
              (room.host?.lowercased().contains(".daily.co") ?? false) else {
            errorMessage = "Room URL must be a valid https://<subdomain>.daily.co URL."
            appendEvent("Rejected join due to invalid room URL.")
            return
        }

        isJoining = true
        defer { isJoining = false }

        #if canImport(Daily)
        do {
            let client = try await ensureClient()

            if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                client.set(username: username, completion: nil)
            }

            let token: MeetingToken? = meetingToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : MeetingToken(stringValue: meetingToken.trimmingCharacters(in: .whitespacesAndNewlines))

            let settings = ClientSettingsUpdate(
                inputs: .set(
                    camera: .set(
                        isEnabled: .set(isCameraEnabled)
                    ),
                    microphone: .set(
                        isEnabled: .set(isMicrophoneEnabled)
                    )
                )
            )

            try await client.join(url: room, token: token, settings: settings)
            client.startLocalAudioLevelObserver(intervalMs: 500, completion: nil)
            client.startRemoteParticipantsAudioLevelObserver(intervalMs: 500, completion: nil)

            appendEvent("Joined room \(room.absoluteString).")
            refreshParticipants()
        } catch {
            errorMessage = "Failed to join room: \(error.localizedDescription)"
            appendEvent("Join failed: \(error.localizedDescription)")
        }
        #else
        errorMessage = "Daily SDK is not available in this build."
        appendEvent("Join blocked because Daily SDK is unavailable.")
        #endif
    }

    func leave() async {
        #if canImport(Daily)
        guard let client = callClient else { return }

        do {
            try await client.stopLocalAudioLevelObserver()
            try await client.stopRemoteParticipantsAudioLevelObserver()
            try await client.leave()
        } catch {
            appendEvent("Leave encountered an error: \(error.localizedDescription)")
        }

        teardownClient()
        appendEvent("Left room.")
        #endif
    }

    func toggleMicrophone() async {
        #if canImport(Daily)
        guard let client = callClient else { return }
        isMicrophoneEnabled.toggle()
        do {
            try await client.setInputsEnabled([.microphone: isMicrophoneEnabled])
            appendEvent(isMicrophoneEnabled ? "Microphone enabled." : "Microphone muted.")
        } catch {
            isMicrophoneEnabled.toggle()
            errorMessage = "Failed to update microphone state: \(error.localizedDescription)"
        }
        #endif
    }

    func toggleCamera() async {
        #if canImport(Daily)
        guard let client = callClient else { return }
        isCameraEnabled.toggle()
        do {
            try await client.setInputsEnabled([.camera: isCameraEnabled])
            appendEvent(isCameraEnabled ? "Camera enabled." : "Camera disabled.")
        } catch {
            isCameraEnabled.toggle()
            errorMessage = "Failed to update camera state: \(error.localizedDescription)"
        }
        #endif
    }

    private func appendEvent(_ message: String) {
        eventLog.insert("[\(Date.now.formatted(date: .omitted, time: .standard))] \(message)", at: 0)
        if eventLog.count > maxEventLogEntries {
            eventLog = Array(eventLog.prefix(maxEventLogEntries))
        }
    }

    #if canImport(Daily)
    private func ensureClient() async throws -> CallClient {
        if let callClient { return callClient }
        let client = CallClient()
        client.delegate = self
        callClient = client
        return client
    }

    private func teardownClient() {
        callClient?.delegate = nil
        callClient = nil
        isJoined = false
        callStateDescription = "left"
        participants = []
        localVideoTrack = nil
        activeSpeakerVideoTrack = nil
        activeSpeakerID = nil
    }

    private func refreshParticipants() {
        guard let callClient else { return }
        let all = callClient.participants.all.values.sorted(by: { lhs, rhs in
            let l = participantDisplayName(lhs)
            let r = participantDisplayName(rhs)
            return l.localizedCaseInsensitiveCompare(r) == .orderedAscending
        })

        participants = all.map { participant in
            DailyCallParticipant(
                id: "\(participant.id)",
                name: participantDisplayName(participant),
                isLocal: participant.info.isLocal,
                isAudioPlayable: participant.media?.microphone.state == .playable,
                isVideoPlayable: participant.media?.camera.state == .playable
            )
        }

        localVideoTrack = callClient.participants.local.media?.camera.track

        if let activeSpeakerID {
            activeSpeakerVideoTrack = all.first(where: { "\($0.id)" == activeSpeakerID })?.media?.camera.track
        } else {
            activeSpeakerVideoTrack = all.first(where: { !$0.info.isLocal })?.media?.camera.track
        }
    }

    private nonisolated func participantDisplayName(_ participant: Participant) -> String {
        participant.info.username ?? (participant.info.isLocal ? "You" : "\(participant.id)")
    }
    #endif
}

#if canImport(Daily)
extension DailyCallBackend: CallClientDelegate {
    nonisolated func callClient(_ callClient: CallClient, callStateUpdated state: CallState) {
        Task { @MainActor in
            callStateDescription = String(describing: state)
            isJoined = (state == .joined)
            appendEvent("Call state changed to \(state).")
        }
    }

    nonisolated func callClient(_ callClient: CallClient, participantJoined participant: Participant) {
        let participantName = participantDisplayName(participant)
        Task { @MainActor in
            appendEvent("\(participantName) joined.")
            refreshParticipants()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, participantLeft participant: Participant, withReason reason: ParticipantLeftReason) {
        let participantID = "\(participant.id)"
        let participantName = participantDisplayName(participant)
        let reasonDescription = String(describing: reason)
        Task { @MainActor in
            appendEvent("\(participantName) left (\(reasonDescription)).")
            if activeSpeakerID == participantID {
                activeSpeakerID = nil
            }
            refreshParticipants()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, participantUpdated participant: Participant) {
        Task { @MainActor in
            refreshParticipants()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, activeSpeakerChanged activeSpeaker: Participant?) {
        let speakerID = activeSpeaker.map { "\($0.id)" }
        let speakerName = activeSpeaker.map(participantDisplayName)
        Task { @MainActor in
            activeSpeakerID = speakerID
            refreshParticipants()
            if let speakerName {
                appendEvent("Active speaker: \(speakerName).")
            }
        }
    }

    nonisolated func callClient(_ callClient: CallClient, inputsUpdated inputs: InputSettings) {
        let cameraEnabled = inputs.camera.isEnabled
        let microphoneEnabled = inputs.microphone.isEnabled
        Task { @MainActor in
            isCameraEnabled = cameraEnabled
            isMicrophoneEnabled = microphoneEnabled
            refreshParticipants()
        }
    }

    nonisolated func callClient(_ callClient: CallClient, error: CallClientError) {
        let description = error.localizedDescription
        Task { @MainActor in
            errorMessage = description
            appendEvent("Error: \(description)")
        }
    }

    // AGENT DECISION: Network-quality and recording delegate callbacks are not resolved from reachable docs in this
    // environment, so these values remain observational placeholders until official callback signatures are confirmed.
}
#endif
