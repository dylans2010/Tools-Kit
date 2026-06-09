import SwiftUI

public struct SubmissionsView: View {
    @StateObject private var viewModel = SubmissionsViewModel()

    public init() {}

    public var body: some View {
        List {
            Section {
                Picker("Status Filter", selection: $viewModel.filter) {
                    Text("All").tag(Optional<FeedbackStatus>.none)
                    ForEach(FeedbackStatus.allCases) { status in
                        Text(status.displayName).tag(Optional(status))
                    }
                }
                .pickerStyle(.menu)
            }

            if viewModel.filteredReports.isEmpty {
                Text("No reports found.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.filteredReports) { report in
                    NavigationLink(destination: SubmissionDetailView(report: report, viewModel: viewModel)) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(report.summary)
                                    .font(.headline)
                                    .lineLimit(1)
                                Spacer()
                                Text(report.status.displayName)
                                    .font(.caption2)
                                    .bold()
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(report.status.color.opacity(0.1))
                                    .foregroundColor(report.status.color)
                                    .cornerRadius(4)
                            }

                            HStack {
                                Label(report.category.displayName, systemImage: report.category.icon)
                                Spacer()
                                Text(report.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Submissions")
        .refreshable {
            await viewModel.fetchReports()
        }
        .task {
            await viewModel.fetchReports()
        }
    }
}
