import SwiftUI

struct JoinMeetingView: View {
    @ObservedObject private var manager = MeetingStateManager.shared
    @State private var navigateToLobby = false
    @State private var showCreateMeetingSheet = false
    @AppStorage("meet_display_name") private var storedDisplayName = ""

    var body: some View {
        List {
            joinMeetingSection
            scheduledMeetingsSection
            setupSection
            errorSection
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
        .onAppear {
            if manager.displayNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                manager.displayNameInput = storedDisplayName
            }
        }
    }

    private var joinMeetingSection: some View {
        Section {
            TextField("Enter Your Name", text: $manager.displayNameInput)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .onChange(of: manager.displayNameInput, initial: false) { _, newValue in
                    storedDisplayName = newValue
                }
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
            .disabled(
                manager.isBusy ||
                !manager.isMeetingIDFormatValid ||
                manager.displayNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        } header: {
            Label("Join Meeting", systemImage: "video.badge.ellipsis")
        } footer: {
            Text("Enter your name and meeting ID to join quickly.")
        }
    }

    private var scheduledMeetingsSection: some View {
        Section {
            if manager.scheduledMeetings.isEmpty {
                ContentUnavailableView(
                    "No Scheduled Meetings",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("You have no meetings scheduled.")
                )
            } else {
                ForEach(manager.scheduledMeetings) { scheduled in
                    scheduledMeetingRow(scheduled)
                }
            }
        } header: {
            Label("Scheduled Meetings", systemImage: "calendar.badge.clock")
        }
    }

    private func scheduledMeetingRow(_ scheduled: ScheduledMeeting) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(scheduled.name)
                .font(.headline)
            if let meetingId = scheduled.meetingId {
                Text("ID: \(meetingId)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            } else {
                Text("ID: Pending Activation")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Text(scheduled.scheduledAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(scheduled.activationState == .active ? "Active" : "Scheduled")
                .font(.caption2)
                .foregroundStyle(scheduled.activationState == .active ? .green : .orange)

            Button("Join This Meeting") {
                Task { await manager.joinScheduledMeeting(scheduled) }
            }
            .buttonStyle(.bordered)
            .disabled(manager.isBusy)
        }
        .padding(.vertical, 4)
    }

    private var setupSection: some View {
        Section {
            Button {
                showCreateMeetingSheet = true
            } label: {
                Label("Create Meeting", systemImage: "plus.circle")
            }
        } header: {
            Label("Meeting Setup", systemImage: "gearshape.2")
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = manager.errorMessage, !errorMessage.isEmpty {
            Section {
                Text(errorMessage)
                    .foregroundColor(.red)
            } header: {
                Label("Status", systemImage: "exclamationmark.triangle.fill")
            }
        }
    }
}
