import SwiftUI

struct ParticipantsView: View {
    let participants: [MeetingParticipant]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                List {
                    Section {
                        ForEach(participants) { participant in
                            participantRow(participant)
                        }
                    } header: {
                        Text("\(participants.count) People in Meeting").font(.caption.bold())
                    }
                    .listRowBackground(Color.workspaceSurface)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func participantRow(_ participant: MeetingParticipant) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(Text(participant.displayName.prefix(1).uppercased()).font(.subheadline.bold()))

            VStack(alignment: .leading, spacing: 2) {
                Text(participant.displayName).font(.subheadline.bold())
                Text(participant.role.displayName).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 16) {
                Image(systemName: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                    .foregroundStyle(participant.isMuted ? .red : .green)
                Image(systemName: participant.hasVideo ? "video.fill" : "video.slash.fill")
                    .foregroundStyle(participant.hasVideo ? .green : .secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
