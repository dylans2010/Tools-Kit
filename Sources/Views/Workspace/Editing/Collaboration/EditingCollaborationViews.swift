import SwiftUI

struct SharedEditingView: View {
    @StateObject private var sessionManager = SharedEditingSessionManager.shared

    var body: some View {
        ZStack {
            // Simulated editing canvas
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)

            Text("Shared Editing Session")
                .foregroundColor(.white)

            // Cursors for other participants
            ForEach(sessionManager.activeParticipants) { participant in
                VStack(spacing: 2) {
                    Image(systemName: "mouse")
                        .foregroundStyle(.secondary)
                    Text(participant.userName)
                        .font(.caption2)
                        .padding(2)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(4)
                }
                .position(participant.position)
            }
        }
        .navigationTitle("Collaboration Session")
    }
}

struct MediaPRView: View {
    let projectID: UUID

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.triangle.pull")
                .font(.system(size: 50))

            Text("Create Change Request")
                .font(.title2)
                .bold()

            Text("Propose your edits to the main media project for review.")
                .multilineTextAlignment(.center)
                .padding()

            Button("Propose Changes") {
                EditingCollaborationBridge.createPRFromProject(projectID: projectID, targetSpaceID: UUID())
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
