import SwiftUI

struct PresenceOverlayView: View {
    @StateObject private var session = CollaborationSessionManager.shared

    var body: some View {
        GeometryReader { _ in
            ForEach(Array(session.cursorPositions.keys), id: \.self) { user in
                if let pos = session.cursorPositions[user] {
                    VStack(alignment: .leading, spacing: 2) {
                        Image(systemName: "cursorarrow.fill")
                            .foregroundColor(.red)
                        Text(user)
                            .font(.system(size: 8, weight: .bold))
                            .padding(2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .position(pos)
                }
            }
        }
    }
}
