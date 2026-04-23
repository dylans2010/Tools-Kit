import SwiftUI

struct CreateMeetingView: View {
    @StateObject private var manager = MeetingStateManager.shared
    @State private var scheduleForLater = false
    @State private var scheduledAt = Date().addingTimeInterval(60 * 15)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            List {
                Section {
                    TextField("Meeting Name", text: $manager.meetingNameInput)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    Toggle("Schedule For Later", isOn: $scheduleForLater)

                    if scheduleForLater {
                        DatePicker(
                            "Scheduled Time",
                            selection: $scheduledAt,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Meeting ID")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let meetingId = manager.currentSession?.meetingId {
                                Text(meetingId)
                                    .font(.headline.monospaced())
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    Button {
                        Task {
                            await manager.createMeeting(
                                scheduleForLater: scheduleForLater,
                                scheduledAt: scheduledAt
                            )
                        }
                    } label: {
                        if manager.isBusy {
                            ProgressView()
                        } else {
                            Label(scheduleForLater ? "Save Schedule" : "Create Meeting", systemImage: scheduleForLater ? "calendar.badge.plus" : "video.badge.plus")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        manager.isBusy ||
                        manager.meetingNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        (scheduleForLater && scheduledAt < Date())
                    )
                } header: {
                    Label("Meeting", systemImage: "video.fill.badge.plus")
                } footer: {
                    Text(scheduleForLater ? "Save a scheduled session participants can join later." : "Create an instant meeting room now.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Create Meeting")
    }
}
