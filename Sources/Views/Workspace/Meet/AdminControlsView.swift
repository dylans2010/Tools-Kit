/*
 * Summary: Admin controls for meeting management.
 * Changes: Implemented mute/kick/admin logic, breakout rooms, and roster management.
 */

import SwiftUI

/// View for meeting administration tasks.
struct AdminControlsView: View {
    @ObservedObject var controller: MeetSessionController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Meeting Roster") {
                    ForEach(controller.callManager.participants) { participant in
                        participantRow(participant)
                    }
                }

                Section("Global Controls") {
                    Button(role: .destructive) {
                        Task { await controller.callManager.muteAll() }
                    } label: {
                        Label("Mute All Participants", systemImage: "mic.slash.circle.fill")
                    }

                    Toggle(isOn: .constant(true)) {
                        Label("Enable Chat", systemImage: "message.fill")
                    }
                }

                Section("Advanced") {
                    Button {
                        createBreakoutRooms()
                    } label: {
                        Label("Create Breakout Rooms", systemImage: "rectangle.3.group.fill")
                    }
                }
            }
            .navigationTitle("Admin Controls")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func participantRow(_ participant: DailyParticipant) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(participant.userName)
                    .font(.headline)
                Text(participant.id)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Menu {
                Button {
                    Task { await controller.callManager.remoteMute(participantID: participant.id) }
                } label: {
                    Label("Mute", systemImage: "mic.slash")
                }

                Button(role: .destructive) {
                    Task { await controller.callManager.kick(participantID: participant.id) }
                } label: {
                    Label("Kick", systemImage: "person.badge.minus")
                }

                Button {
                    Task { await controller.callManager.grantAdmin(participantID: participant.id) }
                } label: {
                    Label("Grant Admin", systemImage: "shield.fill")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
        }
    }

    private func createBreakoutRooms() {
        Task {
            // Create a new room on the fly via Daily API
            do {
                let breakoutRoom = try await DailyService.shared.createRoom(for: nil)
                let msg: [String: Any] = [
                    "type": "invitation",
                    "room": breakoutRoom.roomName,
                    "text": "Join the breakout room!"
                ]
                try? await controller.callManager.sendAppMessage(msg)
                MeetingLogger.info("Breakout room created: \(breakoutRoom.roomName)")
            } catch {
                MeetingLogger.error("Failed to create breakout room: \(error.localizedDescription)")
            }
        }
    }
}
