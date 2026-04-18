import SwiftUI
import UIKit

struct CreateMeetingView: View {
    @StateObject private var controller = MeetSessionController.shared

    var body: some View {
        Form {
            Section("Create Session") {
                TextField("Meeting ID (optional)", text: $controller.meetingIdInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                HStack {
                    Button("Generate ID") {
                        _ = controller.generateMeetingID()
                    }
                    Spacer()
                    if !controller.meetingIdInput.isEmpty {
                        Text(controller.meetingIdInput)
                            .font(.caption.monospaced())
                    }
                }

                Button {
                    Task { await controller.createMeeting() }
                } label: {
                    if controller.isBusy {
                        ProgressView()
                    } else {
                        Text("Create Meeting")
                    }
                }
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
        .navigationTitle("Create Meeting")
    }
}
