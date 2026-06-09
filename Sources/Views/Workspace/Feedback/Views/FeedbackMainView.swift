import SwiftUI

public struct FeedbackMainView: View {
    @StateObject private var viewModel = FeedbackMainViewModel()
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: ReporterFeedbackView()) {
                        Label("Submit New Report", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }

                Section("Activity") {
                    FeedbackActivityTimeline(activities: viewModel.recentActivity)
                }

                Section("Impact") {
                    HStack(spacing: 20) {
                        ImpactStat(title: "Reports", value: "\(viewModel.submissions.count)", color: .blue)
                        ImpactStat(title: "Resolved", value: "\(viewModel.submissions.filter { $0.status == .resolved }.count)", color: .green)
                        ImpactStat(title: "Requests", value: "\(viewModel.requests.count)", color: .orange)
                    }
                    .padding(.vertical, 8)
                }

                Section("Dashboard") {
                    NavigationLink(destination: FeedbackInsightsView()) {
                        Label("Insights & Analytics", systemImage: "chart.bar.xaxis")
                    }
                    NavigationLink(destination: SubmissionsView()) {
                        Label("My Submissions", systemImage: "tray.full.fill")
                    }
                    NavigationLink(destination: FeedbackDraftsView(drafts: viewModel.drafts)) {
                        Label("Drafts", systemImage: "doc.text")
                            .badge(viewModel.drafts.count)
                    }
                }

                Section("Community") {
                    NavigationLink(destination: FeedbackRequestsView()) {
                        Label("Feature Requests", systemImage: "star.fill")
                    }
                    NavigationLink(destination: FeedbackNewsView()) {
                        Label("News & Updates", systemImage: "newspaper.fill")
                    }
                }

                Section("System") {
                    NavigationLink(destination: DiagnosticsCenterView()) {
                        Label("Diagnostics Center", systemImage: "stethoscope")
                    }
                    NavigationLink(destination: FeedbackAdminDebugPanel()) {
                        Label("Admin Debug Panel", systemImage: "hammer.fill")
                    }
                }
            }
            .navigationTitle("Feedback")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.refresh()
            }
        }
    }
}

private struct ImpactStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}
