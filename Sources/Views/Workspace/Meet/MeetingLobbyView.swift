import SwiftUI

struct MeetingLobbyView: View {
    @ObservedObject var manager: MeetingStateManager
    @State private var navigateToMeeting = false

    var body: some View {
        List {
            Section("Session") {
                if let session = manager.currentSession {
                    LabeledContent("Meeting ID", value: session.meetingId)
                        .font(.headline.monospaced())
                }
            }

            Section("Participants") {
                HStack(spacing: 10) {
                    if manager.lobbyState.isLoadingParticipants {
                        ProgressView()
                    }
                    Text(manager.lobbyState.isLoadingParticipants ? "Loading participants..." : "\(manager.participants.count) participant(s) ready")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Device Checks") {
                permissionRow(title: "Microphone", state: manager.lobbyState.microphonePermission, icon: "mic")
                permissionRow(title: "Camera", state: manager.lobbyState.cameraPermission, icon: "video")
            }

            Section {
                Button {
                    Task { await manager.startMeeting() }
                } label: {
                    if manager.isJoining {
                        ProgressView()
                    } else {
                        Label("Join Now", systemImage: "arrow.right.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    manager.isJoining ||
                    manager.isBusy ||
                    manager.lobbyState.isCheckingDevices ||
                    manager.lobbyState.isLoadingParticipants
                )
            }
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
}
