import SwiftUI

struct MeetingSummaryView: View {
    @ObservedObject var manager: MeetingStateManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        aiHeader

                        if manager.meetingSummary.isEmpty {
                            emptyState
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                Label("AI Summary", systemImage: "text.justify.leading")
                                    .font(.headline)
                                    .foregroundStyle(.purple)

                                Text(manager.meetingSummary)
                                    .font(.body)
                                    .padding()
                                    .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }

                        actionButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Intelligence")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var aiHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .top, endPoint: .bottom))
            Text("Meeting Insights").font(.headline)
            Text("AI-powered analysis of your conversation.").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ProgressView().tint(.purple)
            Text("Waiting for transcript...").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var actionButton: some View {
        Button {
            Task { _ = try? await manager.generatePostMeetingSummary() }
        } label: {
            Text("Generate Summary")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple, in: Capsule())
                .foregroundStyle(.white)
        }
    }
}
