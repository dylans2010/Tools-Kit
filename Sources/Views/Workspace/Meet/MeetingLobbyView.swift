import SwiftUI

struct MeetingLobbyView: View {
    @ObservedObject var manager: MeetingStateManager
    @State private var navigateToMeeting = false

    var body: some View {
        List {
            sessionSection
            participantsSection
            deviceChecksSection
            prejoinSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Lobby")
        .navigationDestination(isPresented: $navigateToMeeting) {
            MeetingContainerView(manager: manager)
        }
        .task {
            await manager.runLobbyChecks()
        }
        .onChange(of: manager.phase, initial: false) { _, newValue in
            navigateToMeeting = (newValue == .inMeeting)
        }
    }

    private var sessionSection: some View {
        Section("Session") {
            if let session = manager.currentSession {
                LabeledContent("Meeting ID", value: session.meetingId)
                    .font(.headline.monospaced())
            }
        }
    }

    private var participantsSection: some View {
        Section("Participants") { participantsRow }
    }

    private var deviceChecksSection: some View {
        Section("Device Checks") {
            permissionRow(title: "Microphone", state: manager.lobbyState.microphonePermission, icon: "mic")
            permissionRow(title: "Camera", state: manager.lobbyState.cameraPermission, icon: "video")
        }
    }

    private var prejoinSection: some View {
        Section("Prejoin") {
            PreJoinView(manager: manager) {
                DebugLogger.shared.log("Join button tapped from prejoin.", level: .info, category: "Meet")
                Task { await manager.startMeeting() }
            }
        }
    }

    private func permissionRow(title: String, state: MeetPermissionState, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
            Spacer()
            Text(state.rawValue.capitalized)
                .foregroundStyle(state == .granted ? .green : (state == .denied ? .red : .secondary))
        }
    }

    private var participantsRow: some View {
        HStack(spacing: 10) {
            if manager.lobbyState.isLoadingParticipants {
                ProgressView()
            }
            Text(manager.lobbyState.isLoadingParticipants ? "Loading participants..." : "\(manager.participants.count) participant(s) ready")
                .foregroundStyle(.secondary)
        }
    }
}
