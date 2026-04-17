import SwiftUI

struct BadgesView: View {
    @StateObject private var manager = WorkoutsManager.shared

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(manager.badges) { badge in
                    VStack(spacing: 8) {
                        Image(systemName: badge.id.icon)
                            .font(.title)
                            .foregroundColor(badge.isUnlocked ? .yellow : .secondary)
                        Text(badge.id.rawValue)
                            .font(.footnote.bold())
                            .multilineTextAlignment(.center)
                        Text(badge.isUnlocked ? "Unlocked" : "Locked")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Badges")
    }
}
