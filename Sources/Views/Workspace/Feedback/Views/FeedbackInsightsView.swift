import SwiftUI

public struct FeedbackInsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()
    @StateObject private var submissionsVM = SubmissionsViewModel()

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    InsightCard(insight: WeatherInsight(title: "Total Reports", description: "\(submissionsVM.reports.count)", type: .generic))
                    InsightCard(insight: WeatherInsight(title: "Resolved", description: "\(submissionsVM.reports.filter { $0.status == .resolved }.count)", type: .generic))
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
