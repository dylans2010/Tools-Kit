import SwiftUI

struct MarketplaceDraftListView: View {
    @ObservedObject var marketplaceService = MarketplaceService.shared

    var body: some View {
        List {
            Section("Pending Submissions") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "pencil.and.outline").foregroundStyle(.secondary)
                        Text("Draft Listings").font(.subheadline.bold())
                    }
                    Text("Resume your marketplace registration process. Drafts are automatically saved as you progress through the wizard.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Active Drafts") {
                if marketplaceService.drafts.isEmpty {
                    EmptyStateView(icon: "storefront", title: "No Drafts", message: "Start a new submission from the Marketplace Manager to see it here.")
                } else {
                    ForEach(marketplaceService.drafts) { draft in
                        NavigationLink(destination: MarketplaceSubmissionView(appID: draft.appID)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(draft.metadata.title.isEmpty ? "Untitled Application" : draft.metadata.title).font(.subheadline.bold())
                                Text("Last saved \(draft.lastSavedAt.formatted(date: .abbreviated, time: .shortened))").font(.system(size: 8)).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteDrafts)
                }
            }
        }
        .navigationTitle("Submission Drafts")
    }

    private func deleteDrafts(at offsets: IndexSet) {
        for index in offsets {
            let draft = marketplaceService.drafts[index]
            Task { try? await marketplaceService.deleteDraft(id: draft.id) }
        }
    }
}
