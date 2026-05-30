import SwiftUI

struct MarketplaceListingManagerView: View {
    @ObservedObject var marketplaceService = MarketplaceService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingSubmissionWizard = false
    @State private var selectedAppID: UUID?

    var body: some View {
        List {
            Section("Live & Pending Listings") {
                if marketplaceService.submissions.isEmpty {
                    EmptyStateView(icon: "storefront", title: "No Listings", message: "No active or pending listings.")
                } else {
                    ForEach(marketplaceService.submissions) { submission in
                        listingRow(submission)
                    }
                }
            }

            Section("Draft Submissions") {
                if marketplaceService.drafts.isEmpty {
                    Text("No unfinished drafts.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(marketplaceService.drafts) { draft in
                        NavigationLink(destination: MarketplaceSubmissionView(appID: draft.appID)) {
                            VStack(alignment: .leading) {
                                Text(draft.metadata.title.isEmpty ? "Untitled App" : draft.metadata.title).font(.subheadline.bold())
                                Text("Last saved: \(draft.lastSavedAt.formatted())").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Marketplace Manager")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(appService.apps) { app in
                        NavigationLink(destination: MarketplaceSubmissionView(appID: app.id)) {
                            Text(app.name)
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func listingRow(_ submission: MarketplaceSubmission) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(submission.metadata.title).font(.subheadline.bold())
                    Text("v\(submission.technicalDetails.version)").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(submission.status)
            }

            HStack {
                Text("Submitted \(submission.submittedAt.formatted(date: .abbreviated, time: .omitted))")
                Spacer()
                if let lastStatus = submission.statusHistory.last {
                    Text(lastStatus.timestamp.formatted(.relative(presentation: .numeric)))
                }
            }
            .font(.system(size: 8))
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: SubmissionStatus) -> some View {
        Text(status.rawValue).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(statusColor(status).opacity(0.1), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: SubmissionStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .pendingReview, .underReview: return .orange
        case .approved: return .blue
        case .live: return .green
        case .rejected: return .red
        case .paused: return .yellow
        case .deprecated: return .secondary
        }
    }
}
