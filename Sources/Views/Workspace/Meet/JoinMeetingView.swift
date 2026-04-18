import SwiftUI
import Daily

struct JoinMeetingView: View {
    @StateObject private var controller = MeetSessionController.shared
    @State private var navigateToLobby = false
    @State private var showCreateMeetingSheet = false

    var body: some View {
        List {
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
                        Label("Join", systemImage: "video.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(controller.isBusy || !controller.isMeetingIDFormatValid)
            }

            Section("Meeting Setup") {
                Button {
                    showCreateMeetingSheet = true
                } label: {
                    Label("Create Meeting", systemImage: "plus.circle")
                }
            }

            if let errorMessage = controller.errorMessage, !errorMessage.isEmpty {
                Section("Status") {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Meet")
        .navigationDestination(isPresented: $navigateToLobby) {
            MeetingLobbyView(controller: controller)
        }
        .sheet(isPresented: $showCreateMeetingSheet) {
            NavigationStack {
                CreateMeetingView()
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: controller.phase, initial: false) { _, newValue in
            navigateToLobby = (newValue == .lobby)
        }
    }
}
