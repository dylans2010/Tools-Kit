import SwiftUI

/// View for building and tracking contact intelligence.
struct RelationshipInsightsPanel: View {
    let email: String
    @StateObject private var viewModel = RelationshipInsightsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                } else if let profile = viewModel.profile {
                    header(profile: profile)
                    healthSection(profile: profile)
                    topicsSection(profile: profile)
                }
            }
            .padding()
        }
        .navigationTitle("Relationship Intel")
        .onAppear { viewModel.loadProfile(for: email) }
    }

    private func header(profile: RelationshipProfile) -> some View {
        WorkspaceSurfaceCard {
            HStack {
                VStack(alignment: .leading) {
                    Text(profile.displayName ?? email)
                        .font(.title3.bold())
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(profile.totalInteractionCount) Interactions")
                    .font(.caption2.bold())
            }
        }
    }

    private func healthSection(profile: RelationshipProfile) -> some View {
        VStack(alignment: .leading) {
            Text("Relationship Health")
                .font(.headline)

            WorkspaceSurfaceCard {
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(Int(profile.healthScore * 100))%")
                            .font(.largeTitle.bold())
                            .foregroundStyle(healthColor(score: profile.healthScore))
                        Spacer()
                    }
                    Text("Based on sentiment trends and response speed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func topicsSection(profile: RelationshipProfile) -> some View {
        VStack(alignment: .leading) {
            Text("Top Topics")
                .font(.headline)

            FlowLayout(profile.topTopics) { topic in
                Text(topic)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
    }

    private func healthColor(score: Double) -> Color {
        if score > 0.8 { return .green }
        if score > 0.5 { return .orange }
        return .red
    }
}
