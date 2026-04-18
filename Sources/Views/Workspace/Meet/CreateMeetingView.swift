import SwiftUI
import UIKit
import Daily

struct CreateMeetingView: View {
    @StateObject private var controller = MeetSessionController.shared

    var body: some View {
        List {
            Section("Create Session") {
                TextField("Meeting ID (optional)", text: $controller.meetingIdInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Button {
                    Task { await controller.generateMeetingID() }
                } label: {
                    Label("Generate ID from Daily", systemImage: "sparkles")
                }
                .disabled(controller.isBusy)

                Button {
                    Task { await controller.createMeeting() }
                } label: {
                    if controller.isBusy {
                        ProgressView()
                    } else {
                        Label("Create Meeting", systemImage: "video.badge.plus")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(controller.isBusy)
            }

            if let session = controller.currentSession {
                Section("Meeting ID") {
                    HStack {
                        Text(session.meetingId)
                            .font(.headline.monospaced())
                        Spacer()
                        Button("Copy") {
                            UIPasteboard.general.string = session.meetingId
                        }
                    }
                    Text("Share only this ID.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Create Meeting")
    }
}
