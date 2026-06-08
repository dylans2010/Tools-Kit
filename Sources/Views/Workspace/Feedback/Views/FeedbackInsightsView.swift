import SwiftUI

public struct FeedbackInsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()
    @StateObject private var submissionsVM = SubmissionsViewModel()

    public init() {}

    public body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    InsightCard(title: "Total Reports", value: "\(submissionsVM.reports.count)", icon: "doc.text.fill", color: .blue)
                    InsightCard(title: "Resolved", value: "\(submissionsVM.reports.filter { $0.status == .resolved }.count)", icon: "checkmark.circle.fill", color: .green)
                }

                VStack(alignment: .leading, spacing: 15) {
                    Text("Category Distribution")
                        .font(.headline)

                    ForEach(FeedbackCategory.allCases) { category in
                        let count = viewModel.categoryDistribution[category] ?? 0
                        let percentage = submissionsVM.reports.isEmpty ? 0 : Double(count) / Double(submissionsVM.reports.count)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Label(category.displayName, systemImage: category.icon)
                                Spacer()
                                Text("\(count)")
                            }
                            .font(.subheadline)

                            ProgressView(value: percentage)
                                .tint(Color.blue)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 15) {
                    Text("Status Health")
                        .font(.headline)

                    HStack(spacing: 10) {
                        ForEach(FeedbackStatus.allCases) { status in
                            let count = viewModel.statusCounts[status] ?? 0
                            VStack {
                                Text("\(count)")
                                    .font(.title2.bold())
                                Text(status.displayName)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                            .background(status.color.opacity(0.1))
                            .foregroundColor(status.color)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Insights")
        .task {
            await submissionsVM.fetchReports()
            viewModel.calculateInsights(from: submissionsVM.reports)
        }
    }
}

private struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                Spacer()
            }
            .font(.title2)
            .foregroundColor(color)

            Text(value)
                .font(.title.bold())

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
