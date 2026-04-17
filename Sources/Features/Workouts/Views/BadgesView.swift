import SwiftUI

struct BadgesView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @State private var selectedBadge: BadgeModel?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(manager.badges) { badge in
                    Button {
                        selectedBadge = badge
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: badge.id.icon)
                                .font(.title2)
                                .foregroundStyle(badge.isUnlocked ? .yellow : .secondary)
                            Text(badge.name)
                                .font(.footnote.bold())
                                .multilineTextAlignment(.center)
                            Text(badge.isUnlocked ? "Unlocked" : "Locked")
                                .font(.caption2)
                                .foregroundStyle(badge.isUnlocked ? .green : .secondary)
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
                        Label(badge.name, systemImage: badge.id.icon)
                            .font(.title3.bold())
                        Text(badge.description)
                            .font(.subheadline)
                        Text("Criteria: \(badge.criteria)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(badge.isUnlocked ? "Status: Unlocked" : "Status: Locked")
                            .font(.caption)
                            .foregroundStyle(badge.isUnlocked ? .green : .secondary)
                    }
                }
                .navigationTitle("Badge Info")
            }
        }
    }
}
