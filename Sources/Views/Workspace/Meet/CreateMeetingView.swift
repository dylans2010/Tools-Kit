import SwiftUI

struct CreateMeetingView: View {
    @StateObject private var manager = MeetingStateManager.shared

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            List {
                Section("Meeting") {
                    TextField("Meeting Name", text: $manager.meetingNameInput)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Generated Meeting ID")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(manager.currentSession?.meetingId ?? "Generated after creation")
                            .font(.headline.monospaced())
                            .textSelection(.enabled)
                    }

                    Button {
                        Task { await manager.createMeeting() }
                    } label: {
                        if manager.isBusy {
                            ProgressView()
                        } else {
                            Label("Create Meeting", systemImage: "video.badge.plus")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(manager.isBusy || manager.meetingNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Create Meeting")
    }
}
