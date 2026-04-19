import SwiftUI

struct JoinMeetingView: View {
    @StateObject private var manager = MeetingStateManager.shared
    @State private var navigateToLobby = false
    @State private var showCreateMeetingSheet = false

    var body: some View {
        List {
            Section("Join Meeting") {
                TextField("Meeting ID", text: $manager.meetingIdInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: manager.meetingIdInput, initial: false) { _, _ in
                        _ = manager.validateMeetingID()
                    }

                Button {
                    Task { await manager.joinMeeting() }
                } label: {
                    if manager.isBusy {
                        ProgressView()
                    } else {
                        Label("Join", systemImage: "video.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isBusy || !manager.isMeetingIDFormatValid)
            }

            Section("Scheduled Meetings") {
                if manager.scheduledMeetings.isEmpty {
                    ContentUnavailableView("No scheduled meetings", systemImage: "calendar.badge.exclamationmark")
                } else {
                    ForEach(manager.scheduledMeetings) { scheduled in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(scheduled.name)
                                .font(.headline)
                            Text("ID: \(scheduled.meetingId)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Text(scheduled.scheduledAt, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Button("Join This Meeting") {
                                Task { await manager.joinScheduledMeeting(scheduled) }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Meeting Setup") {
                Button {
                    showCreateMeetingSheet = true
                } label: {
                    Label("Create Meeting", systemImage: "plus.circle")
                }
            }

            if let errorMessage = manager.errorMessage, !errorMessage.isEmpty {
                Section("Status") {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Meet")
        .navigationDestination(isPresented: $navigateToLobby) {
            MeetingLobbyView(manager: manager)
        }
        .sheet(isPresented: $showCreateMeetingSheet) {
            NavigationStack {
                CreateMeetingView()
            }
        }
        .onChange(of: manager.phase, initial: false) { _, newValue in
            navigateToLobby = (newValue == .lobby)
        }
    }
}
