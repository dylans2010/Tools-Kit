import SwiftUI

struct BadgesView: View {
    struct BadgeCatalogItem: Identifiable {
        let id: Int
        let title: String
        let icon: String
        let description: String
    }

    @StateObject private var manager = WorkoutsManager.shared
    @State private var selectedBadge: BadgeCatalogItem?

    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 12)]

    private var catalog: [BadgeCatalogItem] {
        let icons = [
            "rosette", "flame.fill", "figure.run", "figure.cooldown", "figure.strengthtraining.traditional",
            "bolt.heart.fill", "heart.fill", "leaf.fill", "fork.knife", "chart.line.uptrend.xyaxis"
        ]

        return (1...120).map { index in
            BadgeCatalogItem(
                id: index,
                title: "Badge \(index)",
                icon: icons[(index - 1) % icons.count],
                description: "Achievement badge #\(index) earned by completing relevant workout and consistency milestones."
            )
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(catalog) { badge in
                    let unlocked = isUnlocked(badge)
                    Button {
                        selectedBadge = badge
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: badge.icon)
                                .font(.title2)
                                .foregroundStyle(unlocked ? .yellow : .secondary)
                            Text(badge.title)
                                .font(.footnote.bold())
                                .multilineTextAlignment(.center)
                            Text(unlocked ? "Unlocked" : "Badge Locked")
                                .font(.caption2)
                                .foregroundStyle(unlocked ? .green : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Badges")
        .sheet(item: $selectedBadge) { badge in
            NavigationStack {
                List {
                    Section {
                        Label(badge.title, systemImage: badge.icon)
                            .font(.title3.bold())
                        Text(badge.description)
                            .font(.subheadline)
                        Text(isUnlocked(badge) ? "Status: Unlocked" : "Status: Badge Locked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Badge Info")
            }
        }
    }

    private func isUnlocked(_ badge: BadgeCatalogItem) -> Bool {
        let mapped = manager.badges.filter(\.isUnlocked).count
        return badge.id <= max(mapped, 1)
    }
}
