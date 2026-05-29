import SwiftUI

struct MarketplaceListingManagerView: View {
    @ObservedObject var marketplaceService = MarketplaceService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    var body: some View {
        List {
            Section {
                if marketplaceService.submissions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "storefront")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No active listings. Submit your app to the Marketplace to reach more users.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(marketplaceService.submissions) { submission in
                        listingRow(submission)
                    }
                }
            } header: {
                Text("Your Listings")
            }
        }
        .navigationTitle("Marketplace Manager")
    }

    private func listingRow(_ submission: MarketplaceSubmission) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.metadata.title).font(.subheadline.bold())
                Text("v\(submission.technicalDetails.version)").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            statusBadge(submission.status)
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: SubmissionStatus) -> some View {
        Text(status.rawValue).font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(statusColor(status).opacity(0.1), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: SubmissionStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .pendingReview, .underReview: return .orange
        case .approved: return .blue
        case .live: return .green
        case .paused: return .cyan
        case .rejected: return .red
        case .deprecated: return .secondary
        }
    }
}
