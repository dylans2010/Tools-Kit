import SwiftUI

struct MeetingStateView: View {
    @ObservedObject var manager: MeetingStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Session State")
                .font(.headline)
            HStack {
                Label(manager.meetingStateLabel, systemImage: "dot.radiowaves.left.and.right")
                Spacer()
                if let id = manager.currentSession?.meetingId {
                    Text(id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
