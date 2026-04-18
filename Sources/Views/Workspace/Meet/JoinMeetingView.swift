import SwiftUI

struct JoinMeetingView: View {
    @StateObject private var controller = MeetSessionController.shared
    @State private var navigateToLobby = false

    var body: some View {
        Form {
            Section("Join Meeting") {
                TextField("Meeting ID", text: $controller.meetingIdInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: controller.meetingIdInput, initial: false) { _, _ in
                        _ = controller.validateMeetingID()
                    }

                Button {
                    Task { await controller.joinMeeting() }
                } label: {
                    if controller.isBusy {
                        ProgressView()
                    } else {
                        Text("Join")
                    }
                }
                .disabled(controller.isBusy || !controller.isMeetingIDFormatValid)
            }

            Section("Meeting Setup") {
                NavigationLink("Create Meeting") {
                    CreateMeetingView()
                }
            }

            if let errorMessage = controller.errorMessage, !errorMessage.isEmpty {
                Section("Status") {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Meet")
        .navigationDestination(isPresented: $navigateToLobby) {
            MeetingLobbyView(controller: controller)
        }
        .onChange(of: controller.phase, initial: false) { _, newValue in
            navigateToLobby = (newValue == .lobby)
        }
    }
}
