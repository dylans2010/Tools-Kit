import SwiftUI

struct CollabAnalyticsView: View {
    @State private var selectedPeriod: CollabPeriod = .week
    @State private var stats = CollabStats()

    var body: some View {
        List {
            Section("Activity Overview") {
                HStack(spacing: 12) {
                    metricCard(title: "Active Users", value: "\(stats.activeUsers)", icon: "person.2.fill", color: .blue)
                    metricCard(title: "Edits", value: "\(stats.totalEdits)", icon: "pencil", color: .green)
                    metricCard(title: "Comments", value: "\(stats.totalComments)", icon: "bubble.left.fill", color: .purple)
                }
            }

            Section("Period") {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(CollabPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue.capitalized).tag(period)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Activity Heatmap") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edits per day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 3) {
                        ForEach(0..<14, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatmapColor(for: Int.random(in: 0...20)))
                                .frame(width: 18, height: 18)
                        }
                    }
                    HStack {
                        Text("Less")
                        HStack(spacing: 2) {
                            ForEach([0, 5, 10, 15, 20], id: \.self) { level in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(heatmapColor(for: level))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        Text("More")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Top Contributors") {
                ForEach(stats.topContributors) { contributor in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.blue)
                        Text(contributor.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(contributor.contributions) edits")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Content Stats") {
                LabeledContent("Total Documents", value: "\(stats.totalDocuments)")
                LabeledContent("Shared Workspaces", value: "\(stats.sharedWorkspaces)")
                LabeledContent("Active Reviews", value: "\(stats.activeReviews)")
                LabeledContent("Avg Response Time", value: "\(stats.avgResponseMinutes)m")
            }
        }
        .navigationTitle("Collaboration Analytics")
        .task { loadStats() }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title3.bold())
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func heatmapColor(for value: Int) -> Color {
        switch value {
        case 0: return Color(.systemGray5)
        case 1...5: return .green.opacity(0.3)
        case 6...10: return .green.opacity(0.5)
        case 11...15: return .green.opacity(0.7)
        default: return .green.opacity(0.9)
        }
    }

    private func loadStats() {
        stats = CollabStats(
            activeUsers: 12,
            totalEdits: 347,
            totalComments: 89,
            totalDocuments: 45,
            sharedWorkspaces: 8,
            activeReviews: 5,
            avgResponseMinutes: 23,
            topContributors: [
                Contributor(name: "Alice", contributions: 89),
                Contributor(name: "Bob", contributions: 67),
                Contributor(name: "Charlie", contributions: 54),
                Contributor(name: "Diana", contributions: 38),
                Contributor(name: "Eve", contributions: 25),
            ]
        )
    }
}

private struct CollabStats {
    var activeUsers: Int = 0
    var totalEdits: Int = 0
    var totalComments: Int = 0
    var totalDocuments: Int = 0
    var sharedWorkspaces: Int = 0
    var activeReviews: Int = 0
    var avgResponseMinutes: Int = 0
    var topContributors: [Contributor] = []
}

private struct Contributor: Identifiable {
    let id = UUID()
    let name: String
    let contributions: Int
}

private enum CollabPeriod: String, CaseIterable {
    case day, week, month, quarter
}
