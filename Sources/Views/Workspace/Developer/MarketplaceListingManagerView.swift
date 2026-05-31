import SwiftUI

struct MarketplaceListingManagerView: View {
    @ObservedObject var marketplaceService = MarketplaceService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingSubmissionWizard = false
    @State private var selectedAppIDForSubmission: UUID?

    var body: some View {
        List {
            Section("Marketplace Operations") {
                HStack(spacing: 20) {
                    metricItem(label: "Live Listings", value: "\(marketplaceService.submissions.filter { $0.status == .live }.count)", icon: "storefront.fill")
                    metricItem(label: "Pending Review", value: "\(marketplaceService.submissions.filter { $0.status == .pendingReview }.count)", icon: "hourglass")
                }
                .padding(.vertical, 8)
            }

            Section("Active Submissions") {
                if marketplaceService.submissions.isEmpty {
                    EmptyStateView(icon: "storefront", title: "No Listings", message: "You haven't submitted any applications to the marketplace yet.")
                } else {
                    ForEach(marketplaceService.submissions) { submission in
                        submissionRow(submission)
                    }
                }
            }

            Section("Drafts") {
                if marketplaceService.drafts.isEmpty {
                    Text("No active drafts.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(marketplaceService.drafts) { draft in
                        NavigationLink(destination: MarketplaceSubmissionView(appID: draft.appID)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(draft.metadata.title.isEmpty ? "Untitled Draft" : draft.metadata.title).font(.subheadline.bold())
                                    Text("Last saved \(draft.lastSavedAt.formatted(date: .abbreviated, time: .shortened))").font(.system(size: 8)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("DRAFT").font(.system(size: 8, weight: .black)).foregroundStyle(.tertiary)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { try? await marketplaceService.deleteDraft(id: draft.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Marketplace")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingSubmissionWizard = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingSubmissionWizard) {
            submissionTargetPicker
        }
    }

    private func metricItem(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func submissionRow(_ submission: MarketplaceSubmission) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(submission.metadata.title).font(.subheadline.bold())
                    Text("v\(submission.technicalDetails.version)").font(.system(size: 9)).foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(submission.status)
            }

            if !submission.reviewFeedback.filter({ !$0.isResolved }).isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange).font(.system(size: 10))
                    Text("Action Required: \(submission.reviewFeedback.filter({ !$0.isResolved }).count) items").font(.system(size: 9, weight: .bold)).foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: SubmissionStatus) -> some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(statusColor(status).opacity(0.1))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: SubmissionStatus) -> Color {
        switch status {
        case .live: return .green
        case .pendingReview: return .orange
        case .rejected: return .red
        default: return .secondary
        }
    }

    private var submissionTargetPicker: some View {
        NavigationStack {
            List(appService.apps) { app in
                Button {
                    selectedAppIDForSubmission = app.id
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(app.name).font(.subheadline.bold())
                            Text(app.bundleId).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if marketplaceService.submissions.contains(where: { $0.appID == app.id }) {
                            Text("Active Listing").font(.system(size: 8, weight: .bold)).foregroundStyle(.green)
                        } else {
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
                .disabled(marketplaceService.submissions.contains(where: { $0.status == .pendingReview && $0.appID == app.id }))
            }
            .navigationTitle("New Submission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingSubmissionWizard = false } }
            }
            .navigationDestination(item: $selectedAppIDForSubmission) { id in
                MarketplaceSubmissionView(appID: id)
            }
        }
    }
}
