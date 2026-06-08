import SwiftUI

public struct FeedbackMainView: View {
    @StateObject private var viewModel = FeedbackMainViewModel()
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public body: some View {
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
