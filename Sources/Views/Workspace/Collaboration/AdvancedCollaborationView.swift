import SwiftUI

struct AdvancedCollaborationView: View {
    @StateObject private var webSocket = WebSocketManager.shared
    @State private var participants: [String] = ["You", "Jules"]

    var body: some View {
        VStack {
            participantsHeader
            Divider()
            collaborationContent
        }
        .navigationTitle("Advanced Collaboration")
    }

    private var participantsHeader: some View {
        HStack {
            ForEach(participants, id: \.self) { participant in
                Text(String(participant.prefix(1)))
                    .font(.caption.bold())
                    .frame(width: 32, height: 32)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            Text("\(participants.count) active now")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }

    private var collaborationContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Real-time presence and co-editing enabled.")
                .font(.headline)

            Text("Changes made by any participant will propagate instantly across the workspace.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
    }
}
