import SwiftUI

struct WorkspaceAnalyticsView: View {
    @StateObject private var manager = WorkspaceAnalyticsManager.shared
    let space: CollaborationSpace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Usage Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Usage Trend").font(.headline)
                    TrendChart(data: manager.getUsageTrends(for: space.id))
                        .frame(height: 150)
                }
                .padding()
                .background(Color.workspaceSurface)
                .cornerRadius(12)

                // Contribution Table
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Contributors").font(.headline)

                    VStack(spacing: 0) {
                        ContributionRow(name: "Dylan", commits: 45, reviews: 12, isHeader: true)
                        Divider()
                        ContributionRow(name: "Local User", commits: 28, reviews: 5)
                        ContributionRow(name: "Jules AI", commits: 15, reviews: 30)
                    }
                }
                .padding()
                .background(Color.workspaceSurface)
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Workspace Analytics")
    }
}

struct TrendChart: View {
    let data: [Double]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<data.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
                    .frame(width: 20, height: CGFloat(data[index]))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ContributionRow: View {
    let name: String
    let commits: Int
    let reviews: Int
    var isHeader: Bool = false

    var body: some View {
        HStack {
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(commits)")
                .frame(width: 60)
            Text("\(reviews)")
                .frame(width: 60)
        }
        .font(isHeader ? .caption.bold() : .subheadline)
        .padding(.vertical, 8)
        .foregroundColor(isHeader ? .secondary : .primary)
    }
}
