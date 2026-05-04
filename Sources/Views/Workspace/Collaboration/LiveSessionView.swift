import SwiftUI

struct LiveSessionView: View {
    @StateObject private var session = CollaborationSessionManager.shared

    var body: some View {
        ZStack {
            VStack {
                Text("Co-Editing Session")
                    .font(.title2)

                HStack {
                    ForEach(session.activeUsers, id: \.self) { user in
                        Text(user)
                            .padding(8)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Text("Move your finger to sync cursor")
                    .foregroundColor(.secondary)
            }

            PresenceOverlayView()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    session.updateCursor(position: value.location)
                }
        )
        .navigationTitle("Live Session")
    }
}
