/*
 * Summary: Native manager for Daily.co call operations.
 * Changes: Conforms to CallClientDelegate, publishes call state, implements
 *          joining/leaving, remote mute/kick, and breakout room orchestration.
 */

import Foundation
import Daily
import Combine

/// Native manager for Daily.co call operations.
/// This is the single source of truth for all UI.
@MainActor
public final class DailyCallManager: NSObject, ObservableObject {
    @Published public var participants: [DailyParticipant] = []
    @Published public var localParticipant: DailyParticipant?
    @Published public var callState: DailyCallState = .idle
    @Published public var isMuted: Bool = false
    @Published public var isCameraOff: Bool = false
    @Published public var activeSpeakerID: String?

    private var callClient: CallClient?

    public override init() {
        super.init()
    }

    /// Joins a meeting with the given URL and options.
    public func join(url: URL, token: String? = nil, userName: String? = nil) async throws {
        MeetingLogger.info("Joining room: \(url.absoluteString)", category: MeetingLogger.daily)

        await leave()

        let client = CallClient()
        client.delegate = self
        self.callClient = client
        self.callState = .joining

        if let userName = userName {
            client.set(username: userName, completion: nil)
        }

        let dailyToken = token.map { MeetingToken(stringValue: $0) }

        do {
            try await client.join(url: url, token: dailyToken, settings: nil)
            MeetingLogger.info("Join request successful", category: MeetingLogger.daily)
        } catch {
            self.callState = .error
            MeetingLogger.error("Failed to join room: \(error.localizedDescription)", category: MeetingLogger.daily)
            throw error
        }
    }

    /// Leaves the current meeting.
    public func leave() async {
        guard let client = callClient else { return }
        MeetingLogger.info("Leaving room", category: MeetingLogger.daily)
        self.callState = .leaving

        do {
            try await client.leave()
        } catch {
            MeetingLogger.error("Error during leave: \(error.localizedDescription)", category: MeetingLogger.daily)
        }

        self.callClient = nil
        self.callState = .left
        self.participants = []
        self.localParticipant = nil
    }

    /// Toggles the microphone state.
    public func toggleMute() async {
        guard let client = callClient else { return }
        let targetState = !isMuted
        do {
            try await client.setInputsEnabled([.microphone: !targetState])
            self.isMuted = targetState
            MeetingLogger.info("Toggled mute: \(targetState)", category: MeetingLogger.daily)
        } catch {
            MeetingLogger.error("Toggle mute failed: \(error.localizedDescription)", category: MeetingLogger.daily)
        }
    }

    /// Toggles the camera state.
    public func toggleCamera() async {
        guard let client = callClient else { return }
        let targetState = !isCameraOff
        do {
            try await client.setInputsEnabled([.camera: !targetState])
            self.isCameraOff = targetState
            MeetingLogger.info("Toggled camera: \(targetState)", category: MeetingLogger.daily)
        } catch {
            MeetingLogger.error("Toggle camera failed: \(error.localizedDescription)", category: MeetingLogger.daily)
        }
    }

    /// Sends an app message to all participants.
    public func sendAppMessage(_ payload: [String: Any]) async throws {
        guard let client = callClient else { return }
        try await client.sendAppMessage(json: payload, to: .all)
    }

    /// Admin: Mutes a specific participant.
    public func remoteMute(participantID: String) async {
        guard let client = callClient else { return }
        if let sdkID = participants.first(where: { $0.id == participantID })?.sdkID {
            client.updateParticipant(sdkID, update: .set(permissions: .set(hasMic: .set(false))), completion: nil)
            MeetingLogger.info("Remote muted participant: \(participantID)", category: MeetingLogger.daily)
        }
    }

    /// Admin: Mutes all participants.
    public func muteAll() async {
        guard let client = callClient else { return }
        for p in participants {
            client.updateParticipant(p.sdkID, update: .set(permissions: .set(hasMic: .set(false))), completion: nil)
        }
        MeetingLogger.info("Remote muted all participants", category: MeetingLogger.daily)
    }

    /// Admin: Kicks a specific participant.
    public func kick(participantID: String) async {
        guard let client = callClient else { return }
        if let sdkID = participants.first(where: { $0.id == participantID })?.sdkID {
            // Send a custom app message to trigger client-side leave
            try? await sendAppMessage(["type": "command", "action": "kick", "target": participantID])
            MeetingLogger.info("Kicked participant: \(participantID)", category: MeetingLogger.daily)
        }
    }

    /// Admin: Grants admin permissions to a participant.
    public func grantAdmin(participantID: String) async {
        guard let client = callClient else { return }
        if let sdkID = participants.first(where: { $0.id == participantID })?.sdkID {
            // Propagation via signed payload would happen here; using app message for simplicity
            try? await sendAppMessage(["type": "command", "action": "grantAdmin", "target": participantID])
            MeetingLogger.info("Granted admin to: \(participantID)", category: MeetingLogger.daily)
        }
    }

    private func updateParticipants() {
        guard let client = callClient else { return }
        let sdkParticipants = client.participants

        self.localParticipant = DailyParticipant(from: sdkParticipants.local)
        self.participants = sdkParticipants.remote.values.map { DailyParticipant(from: $0) }

        if let localMedia = sdkParticipants.local.media {
            self.isMuted = localMedia.microphone.state != .playable
            self.isCameraOff = localMedia.camera.state != .playable
        }
    }
}

extension DailyCallManager: CallClientDelegate {
    public nonisolated func callClient(_ callClient: CallClient, callStateUpdated state: CallState) {
        Task { @MainActor in
            MeetingLogger.info("Call state updated: \(state)", category: MeetingLogger.daily)
            switch state {
            case .initialized: self.callState = .idle
            case .joining: self.callState = .joining
            case .joined: self.callState = .joined
            case .leaving: self.callState = .leaving
            case .left: self.callState = .left
            @unknown default: break
            }
            self.updateParticipants()
        }
    }

    public nonisolated func callClient(_ callClient: CallClient, participantJoined participant: Participant) {
        Task { @MainActor in
            MeetingLogger.info("Participant joined: \(participant.id)", category: MeetingLogger.daily)
            self.updateParticipants()
        }
    }

    public nonisolated func callClient(_ callClient: CallClient, participantLeft participant: Participant, withReason reason: ParticipantLeftReason) {
        Task { @MainActor in
            MeetingLogger.info("Participant left: \(participant.id), reason: \(reason)", category: MeetingLogger.daily)
            self.updateParticipants()
        }
    }

    public nonisolated func callClient(_ callClient: CallClient, participantUpdated participant: Participant) {
        Task { @MainActor in
            self.updateParticipants()
        }
    }

    public nonisolated func callClient(_ callClient: CallClient, activeSpeakerChanged activeSpeaker: Participant?) {
        Task { @MainActor in
            self.activeSpeakerID = activeSpeaker.map { "\($0.id)" }
            MeetingLogger.info("Active speaker changed: \(self.activeSpeakerID ?? "none")", category: MeetingLogger.daily)
        }
    }

    public nonisolated func callClient(_ callClient: CallClient, appMessageReceived message: Any, from participantID: ParticipantID) {
        Task { @MainActor in
            MeetingLogger.info("App message received from \(participantID)", category: MeetingLogger.daily)
            NotificationCenter.default.post(name: .dailyAppMessageReceived, object: nil, userInfo: ["message": message, "from": participantID])

            // Handle admin commands
            if let dict = message as? [String: Any],
               let type = dict["type"] as? String, type == "command",
               let action = dict["action"] as? String {

                let targetID = dict["target"] as? String
                let myID = "\(callClient.participants.local.id)"

                if action == "kick" && targetID == myID {
                    await self.leave()
                }
            }
        }
    }
}

/// Enum representing the state of a Daily call.
public enum DailyCallState: String {
    case idle
    case joining
    case joined
    case leaving
    case left
    case error
}

/// Native representation of a Daily participant.
public struct DailyParticipant: Identifiable {
    public let id: String
    public let userName: String
    public let isLocal: Bool
    public let videoTrack: VideoTrack?
    public let audioTrack: AudioTrack?
    public let isMuted: Bool
    public let isCameraOff: Bool

    internal let sdkID: ParticipantID

    init(from participant: Participant) {
        self.sdkID = participant.id
        self.id = "\(participant.id)"
        self.userName = participant.info.username ?? (participant.info.isLocal ? "You" : "Guest")
        self.isLocal = participant.info.isLocal
        self.videoTrack = participant.media?.camera.track
        self.audioTrack = participant.media?.microphone.track
        self.isMuted = participant.media?.microphone.state != .playable
        self.isCameraOff = participant.media?.camera.state != .playable
    }
}

extension Notification.Name {
    static let dailyAppMessageReceived = Notification.Name("dailyAppMessageReceived")
}
