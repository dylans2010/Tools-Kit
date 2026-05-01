import SwiftUI

struct LiveCollaborationStudioView: View {
    @StateObject private var manager = LiveStudioManager.shared
    let spaceID: UUID

    var body: some View {
        ZStack {
            // Workspace Surface
            VStack {
                Text("Shared Workspace Surface")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.workspaceSurface)

            // Real-time Cursors
            ForEach(manager.activeParticipants) { participant in
                if let pos = participant.cursorPosition {
                    CursorView(name: participant.name)
                        .position(pos)
                }
            }
        }
        .navigationTitle("Live Studio")
        .overlay(alignment: .topTrailing) {
            ParticipantBar(participants: manager.activeParticipants)
                .padding()
        }
    }
}

struct CursorView: View {
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: "cursorarrow.fill")
                .foregroundColor(.blue)
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
        }
    }
}

struct ParticipantBar: View {
    let participants: [LiveParticipant]

    var body: some View {
        HStack(spacing: -8) {
            ForEach(participants.prefix(5)) { p in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(Text(p.name.prefix(1)).foregroundColor(.white).bold())
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
            }
            if participants.count > 5 {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 32, height: 32)
                    .overlay(Text("+\(participants.count - 5)").foregroundColor(.white).font(.caption))
            }
        }
    }
}
