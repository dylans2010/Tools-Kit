import SwiftUI

struct BreakoutRoomsView: View {
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
                if manager.breakoutRooms.isEmpty {
                    ContentUnavailableView(
                        "No breakout rooms",
                        systemImage: "square.3.layers.3d",
                        description: Text("No breakout rooms are available.")
                    )
                } else {
                    ForEach(manager.breakoutRooms) { room in
                        BreakoutRoomCardView(room: room, participants: manager.participants)
                    }
                }
            }
        }
        .navigationTitle("Breakout Rooms")
    }
}
