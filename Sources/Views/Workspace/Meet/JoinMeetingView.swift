import SwiftUI

struct JoinMeetingView: View {
    @StateObject private var controller = MeetSessionController.shared
    @State private var encryptedIDInput = ""
    @State private var navigateToLobby = false
    @State private var showCreateSheet = false
    @State private var showScheduleSheet = false

    var body: some View {
        List {
            manualJoinSection

            persistedMeetingsSection

            Section {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("Create New Meeting", systemImage: "plus.circle.fill")
                }

                Button {
                    showScheduleSheet = true
                } label: {
                    Label("Schedule for Later", systemImage: "calendar.badge.plus")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Meet")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: DebugView()) {
                    Image(systemName: "ladybug")
                }
            }
        }
        .navigationDestination(isPresented: $navigateToLobby) {
            MeetingLobbyView(controller: controller)
        }
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                CreateMeetingView(controller: controller)
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            scheduleSheet
        }
        .onChange(of: controller.phase) { newValue in
            if newValue == .lobby {
                navigateToLobby = true
            }
        }
    }

    private var manualJoinSection: some View {
        Section("Join with ID") {
            VStack(spacing: 12) {
                TextField("Paste encrypted ID here", text: $encryptedIDInput)
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    Task {
                        await controller.joinMeeting(encryptedID: encryptedIDInput)
                    }
                } label: {
                    if controller.isBusy {
                        ProgressView().tint(.white)
                    } else {
                        Text("Join Meeting")
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(encryptedIDInput.isEmpty || controller.isBusy)
            }
            .padding(.vertical, 4)
        }
    }

    private var persistedMeetingsSection: some View {
        Section("Your Meetings") {
            if controller.persistedMeetings.isEmpty {
                Text("No recent meetings")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(controller.persistedMeetings.sorted(by: { $0.createdAt > $1.createdAt })) { meeting in
                    MeetingRow(meeting: meeting) {
                        Task {
                            await controller.joinMeeting(encryptedID: meeting.encryptedID)
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
        }
    }

    private var scheduleSheet: some View {
        NavigationStack {
            ScheduleMeetingView(controller: controller)
        }
    }
}

struct MeetingRow: View {
    let meeting: PersistedMeeting
    let onJoin: () -> Void

    @State private var timeRemaining: TimeInterval?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.displayName)
                    .font(.headline)

                Text(meeting.encryptedID)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let scheduled = meeting.scheduledTime {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(scheduled, style: .date)
                        Text(scheduled, style: .time)
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)

                    if let remaining = timeRemaining, remaining > 0, remaining < 1800 {
                        Text("Starts in \(formatTime(remaining))")
                            .font(.caption2.bold())
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Button("Join", action: onJoin)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
        .onReceive(timer) { _ in
            if let scheduled = meeting.scheduledTime {
                timeRemaining = scheduled.timeIntervalSince(Date())
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct ScheduleMeetingView: View {
    @ObservedObject var controller: MeetSessionController
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var date = Date()

    var body: some View {
        Form {
            Section("Meeting Info") {
                TextField("Meeting Name", text: $name)
                DatePicker("Time", selection: $date)
            }

            Section {
                Button("Schedule") {
                    Task {
                        await controller.createMeeting(name: name, scheduledTime: date)
                        dismiss()
                    }
                }
                .disabled(name.isEmpty)
            }
        }
        .navigationTitle("Schedule Meeting")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
