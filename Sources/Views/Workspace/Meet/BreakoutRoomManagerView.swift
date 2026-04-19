import SwiftUI

struct BreakoutRoomManagerView: View {
    @ObservedObject var manager: MeetingStateManager
    @State private var newRoomName = ""

    var body: some View {
        List {
            Section("Create Room") {
                TextField("Room name", text: $newRoomName)
                Button("Create") {
                    let name = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    Task { await manager.createBreakoutRoom(named: name) }
                    newRoomName = ""
                }
            }

            Section("Rooms") {
                ForEach(manager.breakoutRooms) { room in
                    BreakoutRoomCardView(room: room, participants: manager.participants)
                }
            }

            Section("Assign Participants") {
                ForEach(manager.participants.filter { $0.role != .host }) { participant in
                    Picker(participant.displayName, selection: breakoutBinding(for: participant.id)) {
                        Text("Main Room").tag(String?.none)
                        ForEach(manager.breakoutRooms) { room in
                            Text(room.name).tag(String?.some(room.id))
                        }
                    }
                }
            }
        }
        .navigationTitle("Breakout Manager")
    }

    private func breakoutBinding(for participantID: String) -> Binding<String?> {
        Binding<String?>(
            get: {
                manager.participants.first(where: { $0.id == participantID })?.breakoutRoomID
            },
            set: { newRoomID in
                Task { await manager.assignParticipant(participantID, to: newRoomID) }
            }
        )
    }
}
