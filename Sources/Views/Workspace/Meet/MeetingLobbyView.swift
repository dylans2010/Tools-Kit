import SwiftUI
import Daily

struct MeetingLobbyView: View {
    @ObservedObject var controller: MeetSessionController
    @State private var navigateToMeeting = false

    var body: some View {
        Form {
            Section("Session") {
                if let session = controller.currentSession {
                    LabeledContent("Meeting ID", value: session.meetingId)
                        .font(.headline)
                }
            }

            Section("Participants") {
                if controller.lobbyState.isLoadingParticipants {
                    HStack {
                        ProgressView()
                        Text("Loading participants...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("\(controller.participants.count) participant(s) ready")
                }
            }

            Section("Device Checks") {
                permissionRow(
                    title: "Microphone",
                    state: controller.lobbyState.microphonePermission,
                    systemImage: "mic"
                )
                permissionRow(
                    title: "Camera",
                    state: controller.lobbyState.cameraPermission,
                    systemImage: "video"
                )
            }

            Section {
                Button("Join Now") {
                    Task {
                        await controller.startMeeting()
                    }
                }
                .disabled(controller.lobbyState.isCheckingDevices || controller.lobbyState.isLoadingParticipants)
            }
        }
        .navigationTitle("Lobby")
        .navigationDestination(isPresented: $navigateToMeeting) {
            MeetingWebView(controller: controller)
        }
        .task {
            await controller.runLobbyChecks()
        }
        .onChange(of: controller.phase, initial: false) { _, newValue in
            navigateToMeeting = (newValue == .inMeeting)
        }
    }

    private func permissionRow(title: String, state: MeetPermissionState, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.secondary)
            Text(title)
            Spacer()
            Text(state.rawValue.capitalized)
                .foregroundColor(state == .granted ? .green : (state == .denied ? .red : .secondary))
        }
    }
}
