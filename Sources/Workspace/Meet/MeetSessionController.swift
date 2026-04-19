import Foundation
import Combine
import Daily
import SwiftUI

@MainActor
final class MeetSessionController: ObservableObject {
    static let shared = MeetSessionController()

    @Published var meetingIdInput = ""
    @Published var meetingNameInput = ""
    @Published var currentSession: MeetingSession?
    @Published var phase: MeetSessionPhase = .idle
    @Published var isBusy = false
    @Published var errorMessage: String?

    @Published var persistedMeetings: [PersistedMeeting] = []

    @Published var messages: [MeetingMessage] = []
    @Published var unreadMessageCount: Int = 0

    @Published var lobbyState = MeetingLobbyState()
    @Published var settings = MeetingSettingsState()
    @Published var summary = MeetingSummaryState()

    public let callManager = DailyCallManager()
    private let resolver: MeetingResolver
    private let permissionService = MeetPermissionService()
    private var cancellables = Set<AnyCancellable>()

    init(resolver: MeetingResolver = .shared) {
        self.resolver = resolver
        loadPersistedMeetings()

        // Listen for messages from DailyCallManager
        NotificationCenter.default.publisher(for: .dailyAppMessageReceived)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let message = userInfo["message"] as? [String: Any],
                      let from = userInfo["from"] as? ParticipantID else { return }
                self.handleAppMessage(message, from: from)
            }
            .store(in: &cancellables)

        // Observe call manager state
        callManager.$callState
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .left: self.phase = .ended
                case .error: self.phase = .failed
                default: break
                }
            }
            .store(in: &cancellables)
    }

    func loadPersistedMeetings() {
        if let data = UserDefaults.standard.data(forKey: "com.app.meet.persistedMeetings"),
           let decoded = try? JSONDecoder().decode([PersistedMeeting].self, from: data) {
            self.persistedMeetings = decoded
        }
    }

    func savePersistedMeeting(_ meeting: PersistedMeeting) {
        persistedMeetings.append(meeting)
        if let data = try? JSONEncoder().encode(persistedMeetings) {
            UserDefaults.standard.set(data, forKey: "com.app.meet.persistedMeetings")
        }
    }

    func createMeeting(name: String, scheduledTime: Date? = nil) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let session = try await resolver.createSession(with: nil)
            let encryptedID = try MeetingCrypto.encryptMeetingID(session.roomName)
            let persisted = PersistedMeeting(displayName: name, encryptedID: encryptedID, scheduledTime: scheduledTime)
            savePersistedMeeting(persisted)

            self.currentSession = session
            self.phase = .lobby
            MeetingLogger.info("Meeting created and persisted: \(name)", category: MeetingLogger.shared)
        } catch {
            errorMessage = error.localizedDescription
            MeetingLogger.error("Failed to create meeting: \(error.localizedDescription)", category: MeetingLogger.shared)
        }
    }

    func joinMeeting(encryptedID: String) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let rawRoomName = try MeetingCrypto.decryptMeetingID(encryptedID)
            let session = try await resolver.joinSession(with: rawRoomName)
            self.currentSession = session
            self.phase = .lobby
        } catch {
            errorMessage = "Invalid Meeting ID or Decryption failed."
            MeetingLogger.error("Join failed: \(error.localizedDescription)", category: MeetingLogger.shared)
        }
    }

    func startMeeting() async {
        guard let session = currentSession else { return }

        do {
            let urlString = "https://\(try await getDailyDomain()).daily.co/\(session.roomName)"
            guard let url = URL(string: urlString) else { throw DailyService.ServiceError.invalidResponse }

            let token = try await DailyService.shared.getMeetingToken(for: session.roomName)

            try await callManager.join(url: url, token: token, userName: UIDevice.current.name)
            self.phase = .inMeeting
            self.unreadMessageCount = 0
        } catch {
            phase = .failed
            errorMessage = error.localizedDescription
        }
    }

    func leaveMeeting() async {
        await callManager.leave()
        phase = .ended
    }

    private func getDailyDomain() async throws -> String {
        // In a real app, this would be fetched from config or parsed from a known URL
        return "your-domain" // Placeholder
    }

    func runLobbyChecks() async {
        lobbyState.isCheckingDevices = true
        async let mic = permissionService.checkMicrophonePermission()
        async let cam = permissionService.checkCameraPermission()
        lobbyState.microphonePermission = await mic
        lobbyState.cameraPermission = await cam
        lobbyState.isCheckingDevices = false
        lobbyState.isLoadingParticipants = false
    }

    func sendChatMessage(_ text: String) {
        let message = ["type": "chat", "text": text, "sender": UIDevice.current.name]
        Task {
            try? await callManager.sendAppMessage(message)
            let localMsg = MeetingMessage(id: UUID().uuidString, threadId: "general", senderName: "You", text: text, sentAt: Date(), isSystem: false)
            messages.append(localMsg)
        }
    }

    private func handleAppMessage(_ message: [String: Any], from: ParticipantID) {
        if let type = message["type"] as? String, type == "chat", let text = message["text"] as? String {
            let sender = (message["sender"] as? String) ?? "Guest"
            let msg = MeetingMessage(id: UUID().uuidString, threadId: "general", senderName: sender, text: text, sentAt: Date(), isSystem: false)
            messages.append(msg)
            if phase != .inMeeting { // Or if chat view is not visible
                 unreadMessageCount += 1
            }
        }
    }
}
